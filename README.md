# CashControl

CashControl es una aplicación móvil multiplataforma orientada a la gestión de finanzas personales. Su objetivo es permitir que los usuarios puedan registrar y controlar ingresos, gastos y presupuestos mediante una aplicación móvil conectada a un backend propio y una base de datos relacional.

## Semana 11 – Navegación, estado y formularios

## Semana 12 – Persistencia local, sesión segura y sincronización

Inventario y clasificación de datos en cliente:

| Clase de dato | Ejemplos | Sensibilidad | Mecanismo |
| --- | --- | --- | --- |
| Credenciales de sesión | access token, refresh token, userId | Alta | flutter_secure_storage cifrado del sistema |
| Datos de negocio visibles | monto, descripción, fecha, categoría, coordenadas y estado de sincronización | Media | SQLite (`expenses`) |
| Operaciones pendientes | payload de creación, intentos, próximo reintento, estado | Media | SQLite (`pending_operations`) |
| Metadatos de sincronización | `last_sync_<userId>` | Baja | SQLite (`app_metadata`) |

Decisiones técnicas de almacenamiento:

- SQLite se mantiene como base local por soporte ACID, transacciones, consultas indexables y migraciones versionadas en Flutter.
- `flutter_secure_storage` se usa para sesión cifrada por plataforma; no se persisten tokens en preferencias de clave/valor.

Esquema local (orientado a lectura y offline-first):

- Tabla `expenses` con campos de UI y control cliente (`last_synced_at`, `sync_status`, `client_operation_id`).
- Tabla `pending_operations` para cola de salida con `attempt_count`, `next_attempt_at`, `status` y `user_id`.
- Versión de esquema en `LocalDatabase` con `onUpgrade` para migrar sin destruir datos.

Sincronización y reconciliación:

- Cada operación cliente usa `client_operation_id` único y estable para reenvíos idempotentes.
- Reintentos exponenciales en cola (1s, 2s, 4s, 8s; máximo 5 intentos) y marca `failed` al exceder límite.
- Al recuperar conectividad, `SyncService` envía la cola y actualiza la lista local.
- Estrategia de conflicto: idempotencia por `client_operation_id` en backend; si llega una operación ya registrada del mismo usuario, se devuelve el registro existente (se sacrifica "última escritura del cliente" en favor de consistencia de servidor por operación).

Timestamps y caducidad:

- Las marcas de reconciliación se toman del servidor (`updated_at` devuelto por API), no del reloj del dispositivo.
- Se aplica caducidad de caché local de 24 horas; la UI muestra aviso visible cuando la caché está vencida y la app permanece offline.
- La pantalla siempre carga desde base local para evitar vistas vacías en ausencia de red.

Minimización y limpieza:

- Solo se persisten campos necesarios para la UI y control de sincronización.
- Al cerrar sesión se limpia almacenamiento seguro completo y datos locales del usuario (`expenses`, `pending_operations`, `app_metadata`).

Datos personales y retención:

- Se almacenan localmente: identificador de usuario, gastos capturados (incluyendo descripción, monto, fecha, y opcionalmente coordenadas/foto local) y cola pendiente.
- Finalidad: continuidad offline, reintentos de sincronización y trazabilidad de estado en UI.
- Retención local: hasta sincronización y uso activo de la sesión; limpieza total al logout del usuario.

Evidencia funcional recomendada para taller:

- Flujo en modo avión: abrir app con datos previos, registrar gasto offline, visualizar estado pendiente.
- Recuperar red: observar sincronización automática y cambio de estado a sincronizado.
- Cerrar sesión: verificar limpieza de sesión y datos locales del usuario.

Uso de IA en esta semana:

- Herramienta: GitHub Copilot (GPT-5.3-Codex).
- Tareas asistidas: revisión de brechas de criterios Semana 12 y ajuste de timestamps/TTL/documentación.
- Verificaciones realizadas: análisis de código, pruebas automatizadas y validación funcional del flujo offline/sync.

Se conecta `go_router` con un `AppController` compartido basado en ChangeNotifier.
El enrutador vive durante toda la aplicación, protege las rutas privadas y permite
reconstruir las pantallas desde su dirección. No se pasan objetos Expense por extra.

| Dirección | Pantalla | Acceso | Endpoint/origen |
| --- | --- | --- | --- |
| `/login` | LoginScreen | Público | POST /api/auth/login |
| `/cargando?from=...` | Restauración de sesión | Público transitorio | Almacenamiento seguro |
| `/gastos` | ExpensesScreen | Autenticado | GET /api/gastos, repositorio y SQLite |
| `/gastos/nuevo` | NewExpenseScreen | Autenticado, anidada | POST /api/gastos o pending_operations |
| `/gastos/:id` | ExpenseDetailScreen | Autenticado, anidada | GET /api/gastos/:id o gasto local por ID |
| `/sin-permiso?from=...` | Acceso denegado | Autenticado | Resultado de HTTP 403 |

Se elige go_router por parámetros de ruta, anidamiento y redirecciones declarativas;
ChangeNotifier basta para el alcance actual sin añadir otro framework de estado.
Una ruta privada solicitada sin sesión se conserva en `from` y se recupera tras
login. El destino se restringe a rutas internas de gastos para evitar redirecciones
externas. El detalle recibe solo el ID de la dirección y consulta el repositorio.

Estado de aplicación: usuario y token privado en AppController, credenciales en
flutter_secure_storage, listado, metadatos de sincronización y borrador del usuario.
Estado efímero: foco, controladores de edición, indicador de captura nativa y mensajes
del formulario. El borrador sobrevive al salir del formulario y regresar mientras
vive la app; se limpia al guardar, cerrar sesión o cambiar de usuario. No se afirma
persistencia del borrador tras matar el proceso. Los gastos y la cola sí usan SQLite.

`OperationState<T>` es un tipo sealed con IdleState, LoadingState, DataState y
ErrorState mutuamente excluyentes. DataState con una lista vacía se presenta mediante
el estado vacío de AsyncStateView. AppButton refleja carga; AppTextField muestra
validación; ExpenseCard abre el detalle. Los gastos locales siguen visibles si
falla la sincronización.

El formulario valida al abandonar campos y al enviar: monto finito positivo con
hasta dos decimales y máximo NUMBER(12,2), descripción obligatoria de hasta 255
caracteres, categoría válida y fechas generadas en UTC. Los errores 422 se asocian
a `amount`/`description`; errores de otros campos aparecen identificados junto al
formulario. El borrador no se pierde si se rechaza el envío. Los inputs se bloquean
durante la solicitud. POST conserva client_operation_id; un fallo de red/servidor
permite conservar una operación local y no se reintenta una creación arbitraria.

401 después del intento de refresh limpia credenciales y redirige al login conservando
el destino; 403 mantiene la sesión y muestra la ruta de permisos insuficientes.
La cámara, ubicación, sus explicaciones y acceso a ajustes siguen disponibles en
Nuevo gasto. No se cambian las tablas ni se eliminan gastos durante la actualización.

Las pruebas de Semana 11 verifican guardias, rechazo de destinos externos, estados
cerrados, login hacia detalle por ID, blur, borrador tras volver al listado, 422 por
campo, guardado y tratamiento distinto de 401/403. Los recorridos de widgets usan
dobles de prueba, no se presentan como una grabación con el backend real. Las pruebas
del backend y la instalación física se verifican por separado.

Resultado del 2 de octubre de 2026: análisis sin problemas, 19 pruebas Flutter
aprobadas y APK debug compilado e instalado en SM A715F sin limpiar SQLite.
Hot restart completado en 4874 ms. La API desde el teléfono devolvió CONNECTED;
los logs de la app mostraron GET /api/gastos 401 seguido de 200 y posteriores
lecturas 200, confirmando la continuidad del refresh y del listado real.

Evidencia manual: iniciar sesión, abrir una tarjeta del listado, volver, completar
Nuevo gasto, regresar al listado y reabrir el formulario, guardar y observar su
detalle. La nueva pantalla de creación reemplaza el diálogo anterior. GitHub Copilot
asistió en la integración; las decisiones se verifican mediante análisis, pruebas
y ejecución física, conservando las funcionalidades de las Semanas 12–14.

## Semana 9 – Entorno móvil verificado

Verificación realizada el 2 de octubre de 2026 sin recrear el proyecto,
reinstalar SDKs ni crear un AVD. El destino usado es el teléfono Android físico
Samsung SM A715F, `R58R11JDHBL`, Android 13/API 33, conectado por USB.

### Equipo y herramientas

| Elemento | Valor observado |
| --- | --- |
| Sistema | Windows 11 Home Single Language, 25H2, build 26200.9550 |
| CPU | Intel Core i3-10110U |
| RAM total / disponible durante la revisión | 15,83 GB / 3,97 GB |
| Espacio libre en C: durante la revisión | 36,30 GB |
| Flutter / Dart | 3.47.0 stable / 3.13.0 |
| Flutter SDK | `C:\src\flutter`, disponible en PATH |
| DevTools | 2.60.0 |
| Visual Studio Code | 1.140.0 |
| Extensiones oficiales | `dart-code.dart-code` y `dart-code.flutter`, ambas 3.144.0 |
| Android Studio | build 261.26222.65.2613.15948027 |
| Java de Android Studio | OpenJDK 25.0.2 |
| Android CLI / cmdline-tools | 23.0 |
| Android platform-tools | 37.0.1; ADB 1.0.41 |
| Android build-tools | 36.0.0 |
| compileSdk / targetSdk / minSdk | 37 / 36 / 24 |
| Node.js / npm | 24.19.0 / 11.17.0 |

El equipo permitió compilar, instalar y ejecutar el proyecto Android. Se recomienda
cerrar procesos pesados durante la compilación por la RAM disponible. Windows informa
`HypervisorPresent=True` y `VirtualizationFirmwareEnabled=False`; bajo un hipervisor
esa lectura no certifica la configuración del firmware. No se modifica BIOS ni se
requiere virtualización para el destino físico elegido.

Flutter se mantiene por reutilización de código, herramientas de depuración y
hot reload, comunidad y plugins nativos. HTTP utiliza `http`/`IOClient`, las
credenciales `flutter_secure_storage` y la navegación existente los mecanismos
de Flutter (`MaterialApp`, `Navigator` y diálogos); no se añade un router externo
sin necesidad. Las versiones resueltas quedan en `mobile/pubspec.lock`; se corrige
su exclusión de Git para reproducibilidad, conservando las exclusiones de secretos
y archivos generados.

### Diagnóstico y limitaciones reales

Se ejecutaron `flutter doctor -v` y `flutter doctor --android-licenses`.

- Android: Flutter todavía reporta licencias en estado desconocido. La CLI Android
   23.0 responde que `--licenses` ya no es necesario y el SDK dispone de
   `licenses/android-sdk-license`. La compilación real funciona, pero no se presenta
   ese hallazgo de doctor como resuelto: requiere una versión compatible del flujo
   de diagnóstico/licencias. No se modifica el SDK ni se simula su aceptación.
- Windows desktop: Visual Studio C++ no está instalado. No bloquea Android;
   compilar para Windows requerirá ese workload en una etapa específica.
- Red: doctor detectó un timeout puntual hacia GitHub. `git ls-remote origin HEAD`
   sí respondió, comprobando conectividad Git; no es un problema de la API local.
- iOS: no se dispone de macOS/Xcode ni de un destino iOS configurado. La alternativa
   es un Mac o runner macOS con Xcode para agregar, compilar y probar esa plataforma,
   con sus credenciales de firma. No se afirma haber validado iOS desde Windows.

Por lo tanto, el destino Android está operativo, pero el diagnóstico global no se
declara completamente verde ni listo para Windows/iOS.

### Transporte local acotado

El manifiesto principal declara `INTERNET` y `usesCleartextTraffic=false`.
Solo `src/debug` referencia una política de red con HTTP permitido para los hosts
exactos `127.0.0.1`, `localhost` y `10.0.2.2`, sin subdominios. La política base
mantiene HTTP bloqueado para otros hosts; no se habilita cleartext globalmente.
Para un backend LAN diferente debe añadirse explícitamente su host a la política
debug o usar HTTPS, no desactivar la seguridad global.

El manifiesto release generado fue verificado: contiene INTERNET, conserva
cleartext=false y no incluye la política debug. `ApiClient` sigue exigiendo HTTPS
en release y el backend también exige certificados cuando se ejecuta en producción.
No se configuran excepciones globales de transporte para iOS.

### Ejecución y evidencias

En una terminal ejecutar el backend:

```powershell
cd C:\Proyectos\cashcontrol\backend
npm start
```

En otra, verificar el destino y establecer el túnel:

```powershell
$adb="$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb devices
& $adb -s R58R11JDHBL reverse tcp:3000 tcp:3000
cd C:\Proyectos\cashcontrol\mobile
flutter run -d R58R11JDHBL --dart-define=API_BASE_URL=http://127.0.0.1:3000
```

La URL es configuración de compilación, no un secreto. En el teléfono físico
se usa loopback con adb reverse; `10.0.2.2` corresponde únicamente al emulador.
Después de reconectar USB debe comprobarse/restablecerse el túnel.

Evidencias verificadas durante esta revisión:

- `flutter build apk --debug`: APK generado correctamente e instalado como
   actualización, sin desinstalar ni limpiar SQLite.
- Actividad `com.example.mobile/.MainActivity`: apertura correcta en SM A715F.
- `flutter attach` y tecla `r`: hot reload completado en 945 ms; 0 bibliotecas
   modificadas, sin necesidad de reinstalar.
- API propia `/api/health`: respuesta `success=true`, `database=CONNECTED`.
- XML principal/debug y manifiesto release generado: políticas de transporte
   separadas, sin excepción HTTP en release.

Para el video conservar capturas de doctor con sus advertencias reales, ejecución
en el teléfono, resultado de hot reload y diagnóstico de API. No mostrar `.env`,
contraseñas, JWT ni claves privadas. GitHub Copilot asistió en inspección y
configuración; la información se verificó con comandos reales, XML generado,
compilación Android, ejecución física y la API propia.

## Semana 8 – Optimización medida del backend

Se midieron y optimizaron las lecturas de `/api/gastos` manteniendo el contrato
de Flutter, autenticación, Oracle y sincronización offline. La medición inicial
detectó tres intentos DDL por solicitud sobre una tabla existente (CREATE y dos
ALTER), conexiones repetidas para lecturas idénticas y doble verificación JWT.

### Resultados antes y después

Entorno: Oracle real local, 30 gastos temporales de un usuario de prueba aislado,
20 solicitudes HTTP secuenciales para cada modalidad. Se incluye la primera lectura
en el promedio. Los registros se eliminan al terminar; no se guardan tokens.

| Métrica | Antes | Después |
| --- | --- | --- |
| Listado completo: promedio | 64,06 ms | 12,84 ms |
| Listado completo: p95 | 71,92 ms | 22,73 ms |
| Listado completo: sentencias execute / 20 solicitudes | 80 | 1 |
| Listado completo: conexiones / 20 solicitudes | 20 | 1 |
| Listado paginado: promedio | 73,59 ms | 16,85 ms |
| Listado paginado: p95 | 94,01 ms | 24,98 ms |
| Listado paginado: sentencias execute / 20 solicitudes | 100 | 2 |
| Listado paginado: conexiones / 20 solicitudes | 20 | 1 |

La mejora del promedio fue aproximadamente 80% y 77% respectivamente en este
escenario de lecturas repetidas dentro del TTL, no una garantía para toda carga.
La primera lectura completa fue 65,86 ms antes y 66,14 ms después: la conexión
fría conserva un coste similar. Las cifras `execute` incluyen DDL, no solo SELECT.
No se afirma reducción de tamaño por caché: el contrato conserva los campos.
La paginación reduce el JSON de unos 9,8 KB (30 gastos) a 3,4 KB (10 gastos);
pequeñas diferencias entre muestras provienen de IDs y fechas de los datos temporales.

Evidencias reproducibles: `backend/benchmark_before.json`,
`backend/benchmark_after.json` y `backend/scripts/benchmark_expenses.js`.

```powershell
node backend/scripts/benchmark_expenses.js measurement
```

Para reproducir exactamente el antes, usar una copia del commit `c681c77` con el
script de benchmark actual; no es necesario revertir el proyecto de trabajo.

### Técnicas aplicadas

- **Inicialización única:** la creación/migración de gastos se realiza en el primer
   uso y se comparte entre solicitudes; si falla, un uso posterior puede reintentar.
- **Cache-aside:** lecturas por usuario y página, TTL de 5 segundos, máximo 128
   entradas y 16 MiB globales; una respuesta mayor a 2 MiB no se cachea. Lecturas
   concurrentes de la misma clave comparten la carga. No se cachean errores ni tokens.
- **Invalidación:** POST, PUT y DELETE invalidan las páginas del propietario después
   de persistir el cambio. Una lectura iniciada antes del cambio no repuebla la caché
   invalidada. JWT y rol se verifican incluso cuando se devuelve una respuesta cacheada.
- **Autenticación:** se elimina la doble verificación de JWT en rutas de gastos.
   Una lectura cacheada hace una verificación y cero conexiones a Oracle, comprobado
   por pruebas. Login/refresh conservan las consultas necesarias para validar la sesión.
- **Selección de campos:** consultas de gastos proyectan explícitamente los campos
   del contrato, en lugar de SELECT *, preservando los metadatos y coordenadas.
- **Paginación:** se mantiene page/limit con máximo de 100; el listado sin parámetros
   sigue siendo completo por compatibilidad con la sincronización móvil actual.

### N+1 y estrategia de carga

No se encontró una consulta N+1 en el listado: los gastos llegan en una sola
consulta de datos y se serializan sin acceder de nuevo a Oracle por fila. La
consulta adicional de COUNT para paginación es constante, no depende del número
de registros y no es un N+1. No se añadió una relación o un ORM artificial para
simular ese problema. Se conserva carga agrupada del conjunto de gastos solicitado
y lectura del detalle bajo demanda; no se cargan perfiles de usuario por gasto.
Si posteriormente se muestran categorías o relaciones, deben obtenerse mediante
JOIN o consulta agrupada, no mediante una consulta por tarjeta.

### Cola de exportación CSV y worker

Se añadió una exportación real de gastos como operación asíncrona de backend:

| Método y ruta | Propósito |
| --- | --- |
| `POST /api/gastos/exportaciones` | Aceptar trabajo (`202`) y devolver job_id y Location |
| `GET /api/gastos/exportaciones/:jobId` | Consultar queued/running/completed/failed |
| `GET /api/gastos/exportaciones/:jobId/archivo` | Descargar CSV completado del mismo usuario |

La consulta de Oracle es asíncrona y acotada; el formateo y escape del CSV se
ejecutan en `worker_threads`, fuera del hilo principal. Máximo 10 trabajos retenidos,
2 concurrentes, 5000 gastos y 5 MiB por archivo. Un worker que no termina en
30 segundos se detiene. Se neutralizan fórmulas de hoja de cálculo en textos.
La exportación es nueva: no se atribuye a ella un cuello de botella previo
inexistente. Esta cola no reemplaza `pending_operations` ni exporta credenciales.

### Límites y verificación

Caché y cola son locales a un proceso: no hay Redis ni cola durable. Tras reiniciar,
los trabajos se pierden; los resultados expiran cinco minutos después de terminar.
En varias instancias se necesita invalidación distribuida y trabajos compartidos.
Cambios realizados directamente en Oracle o desde otro proceso pueden tardar hasta
cinco segundos en reflejarse en lecturas cacheadas. No se cachea HTTP en el teléfono
(`Cache-Control: no-store` se mantiene). La exportación aún no tiene un botón en Flutter.

Se probaron TTL, memoria acotada, invalidación concurrente, aislamiento entre usuarios,
JWT único, CRUD/auth existentes y exportación HTTP/worker contra Oracle real.
GitHub Copilot asistió en la inspección y optimización; las decisiones se contrastaron
con conteos instrumentados, métricas HTTP y pruebas automatizadas, sin inventar N+1
ni resultados. No se modificaron las pantallas, permisos nativos ni SQLite.

## Semana 7 – Autenticación, roles y seguridad

El backend deja de comparar contraseñas en texto plano o depender de un único
usuario fijo. `CC_USERS` en Oracle persiste usuarios, correo (único), hash scrypt,
rol (`user` o `admin`) y estado activo. `CC_REFRESH_SESSIONS` persiste únicamente
el hash SHA-256 y vencimiento del refresh token, con una relación al usuario.
No se altera la tabla de gastos ni la cola offline.

### Recursos y permisos

| Ruta | Acceso | Propósito |
| --- | --- | --- |
| `GET /api/health` | Público | Salud de API y Oracle |
| `GET /api/openapi.json` | Público | Contrato OpenAPI 3.0.3, importable en Swagger/Postman |
| `POST /api/auth/register` | Público | Registro de usuario con correo y contraseña; solo rol `user` |
| `POST /api/auth/login` | Público | Verificación de contraseña y emisión de tokens |
| `POST /api/auth/refresh` | Público, exige refresh válido | Renovación con rotación de sesión |
| `GET /api/auth/me` | `user`, `admin` | Perfil público de la sesión |
| `/api/gastos` y `/api/gastos/:expenseId` | `user`, `admin` y propiedad del recurso | CRUD de los gastos propios; tampoco admin accede a gastos ajenos |
| `GET /api/admin/users` | Solo `admin` | Listado limitado de ID, usuario y rol; sin credenciales |

La aplicación móvil consume login, refresh, listado y creación con el contrato
existente `userId`, `accessToken`, `refreshToken`. Se elimina la contraseña
precargada del formulario Flutter; debe introducirla el usuario. Registro, perfil
y administración están implementados y probados en la API; no se agregan pantallas
móviles nuevas en esta semana del backend.

### Validaciones y tokens

Registro exige usuario de 3 a 100 caracteres (letras, números, punto, guion o
guion bajo), correo válido de hasta 254 caracteres y contraseña de 12 a 128.
El login permite las contraseñas existentes para preservar la cuenta de desarrollo.
Los nombres y correos se normalizan a minúsculas para aplicar unicidad.
El registro público no permite escoger el rol admin.

JWT contiene únicamente `sub`, `role`, tipo, fechas y metadatos de verificación
(`iss`, `aud`; refresh incluye `jti`). Se exige HS256, emisor y audiencia conocidos.
La vigencia por defecto es 15 minutos para acceso y 7 días para refresh; en
desarrollo se conserva `ACCESS_TOKEN_TTL=1m` cuando está configurado para demostrar
la expiración. Cada refresh válido se consume atómicamente y se reemplaza por otro:
la reutilización y dos intentos concurrentes no producen dos sesiones nuevas.
Si el usuario ya no está activo, no puede iniciar ni renovar sesión. El token de
acceso ya emitido sigue siendo válido hasta expirar; no se implementa blacklist.

Se devuelve `401` ante credenciales/token ausente, inválido o vencido; `403` ante
rol insuficiente; `404` para recursos ajenos sin revelar su existencia; `409` para
duplicados; `422` para campos inválidos; `429` ante demasiados intentos de autenticación
y `500` sin detalles internos. Se limita el cuerpo JSON y no se registran tokens,
contraseñas ni encabezados Authorization.

### Configuración y HTTPS

El secreto JWT debe ser aleatorio, con al menos 32 bytes y fuera de Git. El backend
carga su propio `.env`, independientemente del directorio desde el que se ejecute.
Para migrar las credenciales de desarrollo existentes sin imprimirlas:

```powershell
node backend/scripts/migrate_auth_env.js
```

La utilidad convierte `AUTH_PASSWORD` en `AUTH_PASSWORD_HASH` y elimina el valor
en texto plano; también reemplaza el antiguo secreto de ejemplo si sigue presente.
El hash permite inicializar el usuario de desarrollo conservando su ID y gastos.
No se sobrescriben cuentas persistidas si ya existen. Un administrador debe
provisionarse fuera del registro público, mediante `AUTH_ADMIN_USER` y
`AUTH_ADMIN_PASSWORD_HASH` (o configuración controlada por el administrador de Oracle).
No hay contraseñas de administrador por defecto.

En producción `NODE_ENV=production` exige `HTTPS_CERT_FILE` y `HTTPS_KEY_FILE`.
Node utiliza `https.createServer` con esos archivos; si faltan, el servidor no inicia
en HTTP. En desarrollo se conserva HTTP local y el túnel USB. Certificados y claves
deben guardarse fuera del repositorio. El despliegue TLS con certificado real requiere
el certificado de la infraestructura y no se considera probado por la prueba local.

### Riesgos y medidas

- Exposición de credenciales: hashes scrypt con sal aleatoria, comparación resistente
   a diferencias temporales, secretos de entorno, ausencia de contraseñas en Flutter.
- Escalamiento de privilegios/acceso ajeno: rol del JWT firmado, guardia administrativa,
   registro limitado a user y SQL filtrado por propietario.
- Inyección SQL: consultas con variables bind para los datos recibidos.
- Reutilización de refresh: almacenamiento de hashes y rotación atómica de un solo uso.
- Fuerza bruta: límite básico por IP (20 intentos/minuto); es local al proceso y para
   varias instancias se debe sustituir por un limitador distribuido.

### Verificación

```powershell
cd backend
npm test
$env:RUN_ORACLE_TESTS='1'
npm test
Remove-Item Env:RUN_ORACLE_TESTS
node --check server.js
```

Las pruebas cubren registro/login/refresh con Oracle y almacén simulado, duplicados,
validaciones, roles insuficientes, tokens ausentes/vencidos/de tipo incorrecto,
rotación y concurrencia; la suite CRUD sigue comprobando recursos de otros usuarios
y limpieza de registros temporales. También se comprueban referencias OpenAPI y
que producción rechace iniciar HTTP sin certificados. No se imprimen credenciales.
GitHub Copilot asistió en implementación y pruebas; los resultados se contrastaron
con el contrato HTTP y Oracle real, no solo con código generado.

## Semana 6 – CRUD de gastos en el backend

La entidad principal es el gasto, persistido en Oracle 19c en `CC_GASTOS_SYNC`.
Se conserva el contrato utilizado por Flutter, los tokens JWT y el identificador
`client_operation_id` de la cola offline. No se reemplaza la arquitectura existente.

| Método y ruta | Función | Resultado |
| --- | --- | --- |
| `POST /api/gastos` | Crear o sincronizar idempotentemente | `201` al crear; `200` al repetir una operación existente |
| `GET /api/gastos` | Listado completo compatible con la sincronización actual | `200`, `{ success: true, data: [...] }` |
| `GET /api/gastos?page=1&limit=20` | Listado paginado (máximo 100 por página) | `200`, con `pagination: { page, limit, total, pages }` |
| `GET /api/gastos/:expenseId` | Consultar por `server_id` | `200` o `404` |
| `PUT /api/gastos/:expenseId` | Reemplazar los campos editables | `200` o `404` |
| `DELETE /api/gastos/:expenseId` | Eliminación física del registro remoto | `200`; `404` si no existe |

Todos los endpoints de gastos requieren Bearer y filtran por el usuario del JWT.
`GET /api/health` sigue siendo público y comprueba la conexión real con Oracle.

### Validaciones y reglas de negocio

- Monto numérico finito, positivo, con hasta dos decimales y compatible con `NUMBER(12,2)`.
- Descripción obligatoria de hasta 255 caracteres; categoría de hasta 100 caracteres.
- Identificador de operación y usuario obligatorios de hasta 100 caracteres en creación.
- Fechas en formato ISO UTC válido, igual al enviado por Flutter (`DateTime.toIso8601String`).
- Latitud y longitud opcionales, enviadas juntas y dentro de sus rangos geográficos.
- Un usuario solo puede consultar o modificar sus propios gastos.
- Repetir `client_operation_id` para el mismo usuario mantiene un único registro y el esquema Last Write Wins existente.
- Un identificador perteneciente a otro usuario produce `409`, sin permitir apropiarse del registro.

`PUT` recibe `category_id`, `amount`, `description`, `date` y coordenadas opcionales.
No modifica el identificador del gasto, su propietario ni su identificador de operación.
La fecha de actualización de `PUT` procede del servidor. No se implementa `PATCH`
porque el reemplazo completo de los campos editables basta para este alcance.

### Respuestas y seguridad

Las respuestas conservan `success` y `data`; los errores usan
`{ success: false, message, errors? }`. Se devuelve `400` para JSON malformado,
`401` para sesión inválida, `404` para recursos inexistentes o ajenos,
`409` para conflictos de unicidad, `422` para validación y `500` para fallos internos.
No se envían trazas ni detalles de Oracle al cliente.

Se mitigan la inyección SQL con variables bind y el acceso a datos ajenos con
filtros por `USER_ID` derivados del JWT, no de la URL. La paginación limita
el tamaño de consultas solicitadas. Como optimización futura se propone un índice
compuesto sobre `(USER_ID, EXPENSE_DATE, ID_GASTO)` para listado y ordenación;
debe evaluarse con el plan de ejecución antes de añadirlo.

### Consumo móvil y eliminación

Actualmente `HomeScreen` consume listado y creación a través de `ExpenseRepository`
y `ApiService`; la cola local sigue utilizando `POST` con idempotencia.
Detalle, `PUT` y `DELETE` están disponibles y probados en la API, pero no se han
añadido pantallas ni controles móviles para ellos en esta semana del backend.

Se eligió eliminación física para el CRUD del prototipo sin introducir tombstones
ni cambiar el contrato de sincronización. Una eliminación remota no elimina la
copia SQLite automáticamente; las pruebas usan registros temporales de un usuario
separado. Antes de exponer eliminación desde Flutter se debe implementar su
reconciliación local/remota y evitar que una operación pendiente recree el gasto.

### Pruebas y evidencia técnica

```powershell
cd backend
npm test
$env:RUN_ORACLE_TESTS='1'
npm test
Remove-Item Env:RUN_ORACLE_TESTS
node --check server.js
```

La suite `test/expense_crud.test.js` verifica validaciones y el contrato HTTP
con persistencia simulada. La segunda ejecución comprueba el mismo CRUD contra
Oracle real, crea registros temporales de `crud-test-user` y los elimina al finalizar.
Se verifican creación, repetición idempotente, conflicto entre usuarios, listado,
paginación, detalle, actualización, eliminación, recursos inexistentes y solicitudes
no autorizadas. Los fallos internos se verifican con persistencia simulada.
No se imprimen JWT ni credenciales en las evidencias de estas pruebas.

GitHub Copilot asistió en la inspección del contrato, validaciones, endpoints y
pruebas. Los cambios se verificaron con pruebas HTTP automatizadas y persistencia
real en Oracle; no se consideran verificados por generación de código solamente.

## Arquitectura actual

La solución está organizada de la siguiente manera:

Flutter App
↓
API REST
↓
Node.js + Express.js
↓
Oracle Database 19c

La aplicación móvil no se conecta directamente con la base de datos. Toda comunicación se realiza mediante la API REST desarrollada en Node.js.

## Tecnologías utilizadas

### Aplicación móvil

* Flutter 3.47.0
* Dart 3.13.0
* Android SDK 36.0.0
* compileSdk 37 / targetSdk 36
* Teléfono físico Samsung SM A715F, Android 13 – API 33
* Paquete HTTP para consumo de servicios REST

### Backend

* Node.js 24.19.0
* npm 11.17.0
* Express.js
* dotenv
* oracledb

### Base de datos

* Oracle Database 19c
* Docker
* Oracle SQL Developer

## Estructura del proyecto

```text
cashcontrol/
├── mobile/
├── backend/
├── PLAN_DESARROLLO.md
├── README.md
└── .gitignore
```

## Verificación del entorno Flutter

Para comprobar la instalación del entorno se utiliza:

```bash
flutter doctor -v
```

El entorno Android permite compilar y ejecutar en el teléfono físico. Consulte la
sección Semana 9 para las versiones y los hallazgos actuales de diagnóstico,
incluida la incompatibilidad de verificación de licencias.

El diagnóstico puede mostrar una advertencia relacionada con Visual Studio para desarrollo de aplicaciones Windows. Esta advertencia no afecta al proyecto, debido a que CashControl se ejecuta actualmente sobre Android.

## Destino Android

El destino actual es el teléfono físico conectado por USB; no es necesario crear
un emulador para ejecutar o demostrar el proyecto.

Para verificar los dispositivos disponibles:

```bash
flutter devices
```

El teléfono aparece como:

```text
R58R11JDHBL
SM A715F – Android 13 (API 33)
```

## Ejecución de la aplicación Flutter

Desde la carpeta `mobile`:

```bash
flutter pub get
flutter run -d R58R11JDHBL --dart-define=API_BASE_URL=http://127.0.0.1:3000
```

La aplicación puede utilizar Hot Reload durante el desarrollo presionando:

```text
r
```

en la terminal donde se encuentra activo `flutter run`.

## Ejecución del backend

Desde la carpeta `backend`:

```bash
node server.js
```

El backend se ejecuta en:

```text
http://localhost:3000
```

## Configuración de Oracle

Oracle Database 19c se ejecuta mediante Docker.

Para verificar el contenedor:

```bash
docker ps
```

El contenedor utilizado es:

```text
oracle-19c
```

y expone el puerto:

```text
1521
```

La administración de la base de datos se realiza mediante Oracle SQL Developer.

Se creó un esquema independiente para el proyecto denominado:

```text
CASHCONTROL
```

## Variables de entorno del backend

El backend utiliza un archivo `.env` para almacenar información sensible de conexión.

Ejemplo:

```env
DB_USER=CASHCONTROL
DB_PASSWORD=********
DB_CONNECT_STRING=localhost:1521/orcl
PORT=3000
```

El archivo `.env` no debe subirse al repositorio.

## Endpoint de verificación

Se implementó el endpoint:

```text
GET /api/health
```

Este endpoint verifica:

* Funcionamiento de la API.
* Conexión real entre Node.js y Oracle Database.

Respuesta esperada:

```json
{
  "success": true,
  "message": "API de CashControl funcionando correctamente",
  "database": "CONNECTED"
}
```

## Conexión desde Flutter hacia el backend

En el dispositivo físico por USB se configura `adb reverse tcp:3000 tcp:3000`.

La dirección utilizada es:

```text
http://127.0.0.1:3000
```

Con el túnel USB, loopback del teléfono llega al backend del PC. Si se utiliza
un emulador en otro entorno, `10.0.2.2` permite acceder al host; no es la dirección
del destino físico actual.

La URL base se configura en Flutter mediante:

```dart
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
   defaultValue: 'http://127.0.0.1:3000',
);
```

## Prueba de conectividad

La aplicación Flutter dispone actualmente de una opción para probar la conexión con la API.

Al realizar la solicitud se verifica el siguiente flujo:

```text
Flutter
   ↓
API REST
   ↓
Node.js + Express.js
   ↓
Oracle Database
   ↓
Respuesta JSON
   ↓
Flutter
```

Cuando la conexión es correcta, la aplicación muestra:

```text
API de CashControl funcionando correctamente - Base de datos: CONNECTED
```

## Hot Reload

## Semana 13 – Integración móvil con backend

La integración de la Semana 13 conserva SQLite, `pending_operations`,
`client_operation_id` y `SyncService` de la Semana 12, pero centraliza el
consumo HTTP y agrega autenticación real.

### Arquitectura

```text
HomeScreen
   -> ExpenseRepository
       -> ExpenseRemoteDataSource -> ApiService -> ApiClient -> API REST -> Oracle 19c
       -> ExpenseLocalDataSource -> SQLite / pending_operations
```

`ApiClient` es la única instancia reutilizable para HTTP. La URL se configura
con `--dart-define=API_BASE_URL=...`; para un teléfono físico conectado por
USB se puede usar `adb reverse tcp:3000 tcp:3000` y
`http://127.0.0.1:3000`. Para un emulador Android se usa `http://10.0.2.2:3000`.
El cliente aplica timeouts de conexión, recepción y envío, agrega Bearer desde
`flutter_secure_storage`, renueva el token ante 401 una sola vez y reintenta
únicamente GET ante un fallo de red.

### Autenticación y errores

El backend expone `POST /api/auth/login` y `POST /api/auth/refresh` con JWT.
Los tokens solo se almacenan en almacenamiento cifrado. Los errores se
traducen a cuatro familias: sin conexión/timeout, autenticación 401,
validación 422 y error de servidor 5xx. Las creaciones POST no se reintentan
automáticamente y mantienen `client_operation_id` para idempotencia.

### Modelos y divergencias

`Expense` y `User` usan `json_serializable` con archivos `.g.dart` generados.
La persistencia SQLite conserva sus nombres (`local_id`, `expense_date`, etc.)
y el contrato REST conserva `server_id`, `client_operation_id`, `category_id`,
`amount`, `description`, `date`, `created_at` y `updated_at`. No se encontró
una divergencia que requiera `@JsonKey`; el mapeo SQLite se mantiene explícito
en `Expense.toMap` y `Expense.fromMap`.

| Servidor | Cliente | Divergencia |
| --- | --- | --- |
| `server_id` | `serverId` / `server_id` | No se renombra en el contrato REST; SQLite usa `server_id`. |
| `expense_date` | `date` | Solo existe en SQLite; REST usa `date`. |

### Comandos

```text
cd backend
npm install
node server.js

cd mobile
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter run -d R58R11JDHBL --dart-define=API_BASE_URL=http://127.0.0.1:3000
```

En producción se debe usar HTTPS y un `JWT_SECRET` fuerte mediante variables
de entorno. No se deben colocar credenciales, tokens ni secretos en Flutter,
SQLite, logs o `--dart-define`.

El funcionamiento de Hot Reload fue verificado modificando el título de la aplicación desde:

```text
Flutter Demo Home Page
```

a:

```text
CashControl
```

El cambio fue aplicado sin reinstalar completamente la aplicación.

## Estado actual del proyecto

Actualmente se encuentra funcionando:

* Entorno Flutter.
* Android SDK.
* Emulador Pixel 5.
* Aplicación Flutter base.
* Hot Reload.
* Backend Node.js con Express.
* Oracle Database 19c en Docker.
* Conexión backend–Oracle.
* Endpoint `/api/health`.
* Consumo del endpoint desde Flutter.

## Semana 10 – Sistema de diseño y componentes reutilizables

Se implementó en la app Flutter un sistema de diseño centralizado y un catálogo de componentes reutilizables sin romper la arquitectura existente de la Semana 12.

### Sistema de tokens

Se definió un tema central con tokens primitivos y semánticos usando `ThemeData` y `ThemeExtension` en `mobile/lib/core/theme/cashcontrol_theme.dart`.

- Colores base: primario, fondo, superficie, texto principal/secundario, éxito, error, warning, info y bordes.
- Tipografías: tamaños base para cuerpo y títulos.
- Espaciados: `4`, `8`, `12`, `16`, `24`, `32`.
- Radios: `8`, `12`, `16`, `24`.

### Componentes reutilizables

Se añadieron los siguientes widgets reutilizables:

- `AppButton`
- `AppTextField`
- `ExpenseCard`
- `AsyncStateView`

Estos componentes:

- no consultan directamente el backend
- no dependen de rutas ni navegación
- reciben datos por parámetros
- usan callbacks para acciones
- consumen `Theme` y `ThemeExtension`
- permiten contenido delegado

### Accesibilidad

Se aplicaron buenas prácticas para diseño accesible:

- contraste con ratio adecuado para WCAG AA
- mínimo táctil de `48x48` logical pixels
- `Semantics` para acciones y mensajes importantes
- señales no solo por color (iconos, texto y etiquetas)

### Evidencia técnica

La documentación detallada del informe queda en:

- `mobile/docs/semana10_informe_diseno.md`
- `mobile/lib/core/theme/cashcontrol_theme.dart`
- `mobile/lib/widgets/`

El proyecto quedó preparado para generar el informe técnico de la Semana 10 conservando la persistencia local, sincronización offline y flujo actual de gastos implementado en la Semana 12.

## Persistencia local y funcionamiento offline

La aplicación usa SQLite mediante `sqflite`, con migraciones versionadas. La base local contiene `expenses`, `pending_operations` y `app_metadata`. Los gastos se filtran por `user_id`; cada gasto conserva `local_id`, `server_id`, `client_operation_id`, categoría, monto, fechas y estado de sincronización. La versión 2 añade `last_synced_at` sin borrar la base existente.

### Clasificación y minimización de datos

| Dato | Almacenamiento | Finalidad y conservación |
|---|---|---|
| Access/refresh token | `flutter_secure_storage` cifrado por el sistema | Mantener la sesión; hasta logout |
| Identificador mínimo de usuario | almacenamiento seguro y columna `user_id` | Separar los datos locales del usuario; hasta logout |
| Gastos, ingresos, categorías y presupuestos | SQLite local | Lectura offline y sincronización; hasta logout o limpieza |
| Última sincronización | SQLite (`app_metadata`) | Informar antigüedad de la caché; mientras exista la sesión |
| Operaciones pendientes | SQLite (`pending_operations`) | Reintentar escrituras offline; hasta éxito, fallo definitivo o logout |
| Formularios temporales | memoria de la pantalla | No se persisten innecesariamente |

No se guardan contraseñas ni tokens en SQLite o almacenamiento simple clave/valor.

### Lectura y escritura offline

Al iniciar una sesión se leen primero los gastos locales. Si hay red, se actualizan desde `GET /api/gastos`; sin red, la pantalla muestra los datos almacenados y el texto `Sin conexión / Datos desactualizados` junto con la antigüedad real de `last_synced_at`. Un gasto creado sin conexión se guarda inmediatamente con `client_operation_id`, aparece con `Pendiente de sincronización` y se inserta en `pending_operations`.

`SyncService` escucha `connectivity_plus` y procesa la cola al recuperar conectividad. Usa como máximo cinco intentos con espera creciente de 1, 2, 4, 8 y 8 segundos. Una operación agotada queda en estado `failed` para diagnóstico o reintento manual, sin bucles infinitos.

### Backend, idempotencia y conflictos

`POST /api/gastos` acepta `client_operation_id` y usa la tabla Oracle `CC_GASTOS_SYNC`, cuya restricción única evita duplicados al reintentar. El `MERGE` aplica Last Write Wins comparando `UPDATED_AT` del servidor; la marca de reconciliación procede del servidor. Es una estrategia sencilla que puede sobrescribir cambios previos y no conserva automáticamente ambas versiones.

### Logout y datos personales

Cerrar sesión elimina access token, refresh token, credenciales seguras, gastos del usuario, operaciones pendientes, metadatos de sincronización y estado en memoria antes de volver a la pantalla de inicio. Así no quedan datos financieros del usuario anterior en la aplicación.

Las funcionalidades definitivas de CashControl, como autenticación, roles, CRUD, ingresos, gastos, presupuestos y optimización del backend, continuarán desarrollándose progresivamente.

## Semana 14 – Funcionalidades nativas

Se incorporaron dos capacidades nativas del dispositivo al prototipo integrado en la Semana 13, sin modificar la persistencia local ni el backend existentes.

### Capacidades seleccionadas y justificación

| Capacidad | Esencial/Opcional | Justificación |
| --- | --- | --- |
| Cámara (foto del recibo) | Opcional | Permite adjuntar evidencia visual de un gasto. La app funciona igual sin la foto. |
| Ubicación (GPS) | Opcional | Permite registrar el lugar donde ocurrió el gasto. La app funciona igual sin la ubicación. |

Ambas se solicitan únicamente al pulsar los botones **"Adjuntar foto del recibo"** y **"Adjuntar ubicación"** dentro del diálogo **Nuevo gasto**, nunca al iniciar la aplicación.

### Verificación de los plugins adoptados

| Plugin | Versión | Criterios verificados |
| --- | --- | --- |
| `image_picker` | 1.2.3 | Mantenido por el equipo de Flutter (`flutter favorite`), sin permisos de galería (usa el selector/cámara del sistema), actualizado activamente. |
| `geolocator` | 14.0.2 | Paquete líder de la comunidad para geolocalización, expone por separado el permiso y el estado del servicio de ubicación (`isLocationServiceEnabled`), mantenido activamente. |
| `permission_handler` | 13.0.2 | Estándar de facto para gestionar los cuatro estados de permisos runtime en Flutter (`granted`, `denied`, `permanentlyDenied`, `restricted`/`limited`), mantenido activamente. |

No se utilizó ningún plugin de galería ni de almacenamiento de archivos multimedia: la captura de fotos usa directamente la cámara del sistema (`ImageSource.camera`), por lo que no se declaran permisos de acceso amplio a la galería.

### Permisos declarados

**Android** (`mobile/android/app/src/main/AndroidManifest.xml`):

| Permiso | Propósito concreto en CashControl |
| --- | --- |
| `android.permission.CAMERA` | Fotografiar el recibo de un gasto nuevo. |
| `android.permission.ACCESS_FINE_LOCATION` | Obtener coordenadas precisas del lugar de un gasto. |
| `android.permission.ACCESS_COARSE_LOCATION` | Alternativa de menor precisión para la misma función. |

Se declararon además `<uses-feature android:name="android.hardware.camera" android:required="false"/>` y su variante `autofocus`, para no excluir en la tienda a dispositivos sin cámara.

**iOS** (cadenas de propósito a declarar en `Info.plist` si se agrega la plataforma; este proyecto se desarrolla y prueba en Android físico):

| Clave | Texto de propósito |
| --- | --- |
| `NSCameraUsageDescription` | "CashControl necesita acceder a la cámara para fotografiar el recibo de un gasto." |
| `NSLocationWhenInUseUsageDescription` | "CashControl necesita tu ubicación para registrar el lugar donde ocurrió un gasto." |

### Gestión de los cuatro estados de permiso

`mobile/lib/services/camera_capture_service.dart` y `mobile/lib/services/location_capture_service.dart` encapsulan la solicitud y devuelven un resultado tipado con los cuatro estados:

- **Concedido (`granted`)**: se ejecuta la captura (foto o coordenadas) y se adjunta al gasto.
- **Denegado (`denied`)**: se informa al usuario y se permite volver a intentarlo.
- **Denegado permanentemente (`permanentlyDenied`)**: se muestra un botón **"Abrir ajustes"** que invoca `openAppSettings()` (cámara) o `Geolocator.openAppSettings()` (ubicación).
- **Restringido (`restricted`)**: se informa que el sistema operativo bloquea la capacidad (por ejemplo, control parental) y se continúa sin ella.

Para ubicación existe un quinto caso, verificado por separado del permiso: **servicio de ubicación (GPS) desactivado**, detectado con `Geolocator.isLocationServiceEnabled()`, con botón **"Abrir ajustes"** que lleva a `Geolocator.openLocationSettings()`.

### Matriz de degradación

| Situación | Comportamiento de la aplicación |
| --- | --- |
| Permiso concedido | Se adjunta la foto o la ubicación al gasto; se guarda localmente y se envía al backend si hay conexión. |
| Permiso denegado | Se informa el motivo; el gasto puede guardarse sin foto ni ubicación. |
| Permiso denegado permanentemente | Se muestra botón para abrir los ajustes de la aplicación; el gasto puede guardarse sin la capacidad. |
| Permiso restringido | Se informa que la capacidad no está disponible en el dispositivo; el gasto puede guardarse igualmente. |
| GPS desactivado (permiso concedido) | Se informa que el servicio de ubicación está apagado, con botón para abrir los ajustes de ubicación. |
| Sin conexión al guardar | El gasto (con o sin foto/ubicación) se guarda en SQLite y en `pending_operations`, igual que en la Semana 12. |

### Integración con persistencia local y backend

- `mobile/lib/services/local_database.dart`: la tabla `expenses` incorpora las columnas `receipt_photo_path`, `latitude` y `longitude` (migración de versión 2 a 3, sin pérdida de datos).
- `mobile/lib/models/expense.dart`: agrega `receiptPhotoPath` (solo local, no se envía al backend), `latitude` y `longitude` (sí se envían).
- `mobile/lib/repositories/expense_repository.dart`: `createOfflineExpense` acepta los tres campos opcionales; al sincronizar una operación pendiente se preserva la foto local (que el backend no almacena) y se conservan las coordenadas ya sincronizadas.
- `backend/server.js`: la tabla `CC_GASTOS_SYNC` agrega columnas `LATITUDE`/`LONGITUDE` (con migración automática para instalaciones existentes) y el endpoint `POST /api/gastos` valida y persiste ambas de forma opcional.

### Cumplimiento de la tienda y nivel de API

- No se declaran permisos de acceso amplio a la galería ni al almacenamiento; solo cámara y ubicación, ambos justificados por una función concreta.
- `compileSdk`/`targetSdk` del proyecto usan el valor por defecto de Flutter para este SDK: **API 36 (Android 16)**, ya conforme con la exigencia de Google Play vigente desde el 31 de agosto de 2026.

### Casos de prueba en dispositivo físico

| # | Caso | Resultado esperado |
| --- | --- | --- |
| 1 | Adjuntar foto con permiso de cámara concedido | La foto se captura y se muestra en el diálogo antes de guardar. |
| 2 | Adjuntar foto denegando el permiso | Mensaje de permiso denegado; se puede reintentar o guardar sin foto. |
| 3 | Adjuntar foto con denegación permanente | Botón "Abrir ajustes" visible; al conceder el permiso desde ajustes y reintentar, funciona. |
| 4 | Adjuntar ubicación con GPS apagado | Mensaje de servicio de ubicación desactivado, distinto del mensaje de permiso denegado. |
| 5 | Crear gasto con foto y ubicación sin conexión, luego sincronizar | El gasto se guarda localmente, se sincroniza al recuperar conexión y conserva la foto local y las coordenadas remotas. |

Estos cinco casos deben ejecutarse y grabarse en el teléfono Android físico usado durante el proyecto, no en el emulador.

