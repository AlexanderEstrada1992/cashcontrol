# Semana 10 – Informe técnico de diseño de interfaces y componentes reutilizables

## 1. Descripción de CashControl

CashControl es una aplicación móvil multiplataforma para la gestión de finanzas personales. La implementación actual usa Flutter como cliente móvil, Node.js + Express como API REST y Oracle Database como almacenamiento persistente.

El flujo que se mantiene en la solución real es:

- Flutter consulta y presenta la información del usuario.
- La API REST expone los endpoints reales de gastos.
- Node.js comunica la aplicación con Oracle Database.
- La aplicación conserva un almacenamiento local con SQLite para soporte offline, sincronización y cola de operaciones.

La funcionalidad principal ya implementada en la versión actual es la gestión de gastos con persistencia local y sincronización con el backend.

## 2. Inventario real de pantallas y endpoints

### 2.1 Endpoints reales del backend

Se verificó la implementación existente en `backend/server.js`.

| Endpoint | Método | Funcionalidad | Pantalla Flutter que lo utiliza |
| --- | --- | --- | --- |
| `/api/health` | GET | Verifica que la API responda y que exista conexión con Oracle. | `HomeScreen` (`checkApiConnection`) |
| `/api/gastos` | GET | Recupera gastos del propietario identificado por JWT. | `HomeScreen` carga datos locales y sincronización remota, usando `ExpenseRepository.refreshFromServer()` |
| `/api/gastos` | POST | Crea o actualiza un gasto en el backend a partir de `client_operation_id` y payload del gasto. | `HomeScreen` al sincronizar cola de operaciones con `ExpenseRepository.syncPending()` |

### 2.2 Pantallas reales existentes en Flutter

Se verificó la implementación actual en `mobile/lib/main.dart`.

| Pantalla o vista | Estado | Funcionalidad actual |
| --- | --- | --- |
| `HomeScreen` | Actual | Gestiona sesión JWT, diagnóstico de API, conexión, sincronización, gastos locales y cola de operaciones. |
| Vista de login | Actual | Usuario, contraseña y errores de validación del backend. |
| Formulario Nuevo gasto | Actual (diálogo) | Monto, descripción y capacidades nativas opcionales; controles del catálogo. |
| `AsyncStateView` | Nueva en Semana 10 | Maneja estados de carga, vacío y error para la vista de contenido. |

> La aplicación no contiene varias pantallas especializadas de gastos; la funcionalidad real se concentra en la pantalla principal `HomeScreen`, que es la pantalla que debe ser reutilizada para el informe técnico y la evidencia final.

Inventario derivado de endpoints adicionales: registro (`POST /api/auth/register`),
perfil (`GET /api/auth/me`), detalle/edición (`GET/PUT /api/gastos/:id`), administración
(`GET /api/admin/users`) y exportaciones. Estos endpoints existen en la API, pero
sus pantallas móviles todavía no se implementan. No se presentan como vistas reales.
Los patrones candidatos en login, registro y edición son campos con errores y acciones
con estado de carga; en listado, detalle y perfil son encabezados, datos y estados
asíncronos. La reutilización actual se demuestra en login, principal y diálogo, sin
inventar tres pantallas completas para justificar el catálogo.

## 3. Sistema de diseño centralizado

Se implementó un sistema de diseño centralizado en `mobile/lib/core/theme/cashcontrol_theme.dart` con `ThemeData` y `ThemeExtension`.

### 3.1 Tokens primitivos

- Colores base: `primary`, `surface`, `background`, `textPrimary`, `textSecondary`, `success`, `error`, `warning`, `info`, `border`, `muted`
- Tipografías: tamaños base `14`, `16`, `20`, `24`
- Espaciados: `4`, `8`, `12`, `16`, `24`, `32`
- Radios: `8`, `12`, `16`, `24`

### 3.2 Tokens semánticos

Los componentes del proyecto consumen los tokens semánticos usando `Theme.of(context).extension<CashControlColors>()` y el `ColorScheme` del `ThemeData`.

- `primary`: azul principal de la marca
- `surface/background`: fondo de la app y cards
- `textPrimary`: texto principal
- `textSecondary`: texto secundario
- `success`: verde para estados correctos
- `error`: rojo para errores
- `warning`: amarillo/naranja para advertencias
- `info`: azul de información

### 3.3 Uso en componentes

Los widgets reutilizables invocan `Theme.of(context)` y no definen colores o radios arbitrarios dentro del componente.

Ejemplos reales en el proyecto:

- `AppButton` usa `colors.primary`, `colors.onPrimary`, `colors.radiusMd`, `colors.spacingLg`
- `AppTextField` usa `InputDecorationTheme` del tema
- `ExpenseCard` usa `colors.warning`, `colors.success`, `colors.muted`, `colors.radiusMd`
- `AsyncStateView` usa `colors.error`, `colors.info`, `colors.textSecondary`

## 4. Contraste y WCAG AA

Se verificó el sistema con los valores reales del tema:

| Par de colores | Fondo | Texto | Relación | Resultado |
| --- | --- | --- | --- | --- |
| Texto principal sobre fondo | `#F6F8FF` | `#101828` | 16.72:1 | AA superado |
| Texto secundario sobre fondo | `#F6F8FF` | `#475467` | 7.24:1 | AA superado |
| Texto sobre color primario | `#2E6DEB` | `#FFFFFF` | 4.66:1 | AA superado |
| Texto sobre error | `#B42318` | `#FFFFFF` | 6.57:1 | AA superado |
| Texto sobre success | `#027A48` | `#FFFFFF` | 5.41:1 | AA superado |

Las pruebas calculan luminancia relativa con `Color.computeLuminance()` y contrastan
14 combinaciones textuales contra 4.5:1. También verifican el icono primario sobre
muted (4.23:1) contra el mínimo no textual de 3:1. No se aplica el umbral de texto
a bordes puramente decorativos. Esto verifica los pares probados, no certifica por
sí solo toda la aplicación como conforme a WCAG 2.2.

### Método

Se calculó la relación de contraste usando la fórmula estándar WCAG, basada en luminancia relativa de cada color. La aplicación usa fondos claros y texto oscuro, y además utiliza texto blanco sobre colores de alto contraste para acciones y estados de éxito/error.

### Corrección aplicada

Se evitó usar un azul o rojo muy claro sobre fondo blanco. El diseño final usa textos oscuros sobre fondos claros y blanco sobre los colores de acción/estado más intensos para respetar el nivel AA.

## 5. Catálogo de componentes reutilizables implementados

### 5.1 `AppButton`

- Propósito: acción principal o secundaria con tamaño táctil mínimo, estados de carga y deshabilitado.
- Entrada: `label`, `icon`, `loading`, `enabled`, `variant`, `fullWidth`, `onPressed`
- Presentación: usa tokens del tema para colores, radios y espaciado.
- Callbacks: `onPressed`
- Estados: normal, cargando, deshabilitado
- Reutilización: se usa en `HomeScreen` para iniciar sesión, probar conexión y agregar gastos.

### 5.2 `AppTextField`

- Propósito: entrada genérica de texto con estilo consistente.
- Entrada: `controller`, `label`, `hintText`, `prefixIcon`, `keyboardType`, `obscureText`, `validator`, `onChanged`, `errorText`
- Presentación: se integra con `InputDecorationTheme` del tema.
- Callbacks: `onChanged`, `validator`
- Estados: normal, foco, error
- Reutilización: puede ser usado para formulario de gastos, autenticación o filtros.

### 5.3 `ExpenseCard`

- Propósito: visualizar un gasto con estado de sincronización.
- Entrada: `expense`, `onTap`, `showStatus`
- Presentación: icono de recibo, monto, descripción y estado de sincronización.
- Callbacks: `onTap`
- Estados: sincronizado, pendiente,
- Reutilización: el contenido es independiente del backend y usa exclusivamente el modelo `Expense`.

### 5.4 `AsyncStateView`

- Propósito: manejar explícitamente estados de carga, vacío y error.
- Entrada: `loading`, `error`, `empty`, `content`
- Presentación: mensajes con iconos, color semántico y card central.
- Callbacks: sin callbacks propios, delega el contenido al padre mediante `content`.
- Estados: cargando, error, vacío, normal/éxito
- Reutilización: usada en la pantalla principal para la lista de gastos.

## 6. Interfaz pública y código real

Los archivos fuente reales están en:

- `mobile/lib/core/theme/cashcontrol_theme.dart`
- `mobile/lib/widgets/app_button.dart`
- `mobile/lib/widgets/app_text_field.dart`
- `mobile/lib/widgets/expense_card.dart`
- `mobile/lib/widgets/async_state_view.dart`
- `mobile/lib/main.dart`

Cada componente cumple estas condiciones:

- No consulta directamente el backend.
- No conoce rutas ni navegación.
- No depende de una pantalla concreta.
- Recibe datos por parámetros.
- Emite acciones por callbacks.
- Consume `Theme` y `ThemeExtension`.
- Delega el contenido cuando corresponde.

| Componente | Parámetros obligatorios | Opcionales y valores por defecto | Acciones/contenido |
| --- | --- | --- | --- |
| `AppButton` | `label`, `onPressed` (admite null) | `icon=null`, `loading=false`, `enabled=true`, `variant=primary`, `fullWidth=false` | Callback de acción; etiqueta y estado de carga semánticos |
| `AppTextField` | Ninguno | controller/label/hintText/prefixIcon/keyboardType/validator/onChanged/errorText nulos; `obscureText=false` | Callbacks onChanged/validator; errores con texto envolvente |
| `ExpenseCard` | `expense` | `onTap=null`, `showStatus=true` | Callback opcional, modelo independiente de API |
| `AsyncStateView` | `loading`, `error` (admite null), `empty`, `content` | Mensajes predeterminados de carga/error/vacío | Delega contenido normal mediante `content`; prioridad carga, error, vacío, contenido |

Las razones de reutilización son tamaño táctil/estados compartidos, entradas con
validación consistente, representación repetida de gastos y presentación uniforme
de resultados asíncronos. Los componentes no contienen HTTP, SQL ni rutas Navigator;
la pantalla les entrega callbacks y datos.

## 7. Pantalla real ensamblada

La pantalla real que se actualizó es `HomeScreen` en `mobile/lib/main.dart`.

Se reutilizaron los componentes como sigue:

- `AppButton` para sesión, conexión y nueva acción de gasto
- `AsyncStateView` para estados de carga, vacío y error
- `ExpenseCard` para cada gasto local
- `AppTextField` en login y formulario de gastos

El formulario y la explicación de permisos utilizan `AppButton` en sus acciones.
Se mantienen widgets estructurales de Flutter (Scaffold, Text, layouts, AlertDialog),
sin duplicar controles interactivos fuera del catálogo. El login es desplazable;
botones, estados y adjuntos admiten ajuste de línea con fuente ampliada. Los gastos
locales permanecen visibles cuando falla la sincronización; el error se muestra en
el banner. La traducción de fallos de red/autenticación/validación/servidor sigue en
la capa API y no introduce consultas en los componentes.

La pantalla se mantiene compatible con la funcionalidad de sincronización de la Semana 12 sin romper las capas existentes de SQLite, sincronización y API.

## 8. Accesibilidad

### 8.1 Contraste

Se verifica el uso de color con ratios adecuada para AA.

### 8.2 Área táctil

Todos los botones usan un `minimumSize` de `48x48` logical pixels.

### 8.3 Etiquetas semánticas

Se emplean `Semantics` para:

- botón de iniciar sesión
- botón de cerrar sesión
- botón `AppButton`
- tarjetas de gasto
- vistas de estado vacío y error

### 8.4 No depender solo del color

Los estados se comunican con:

- texto explicativo
- icono
- color semántico

## 9. Diseño adaptativo y fuente ampliada

La pantalla principal hace uso de `LayoutBuilder` para detectar dos anchuras:

- ancho pequeño: para compact devices
- ancho mayor: para layouts con tarjeta resúmen lateral

Además, la interfaz usa tamaños y espaciados del sistema para evitar overflow y soportar texto ampliado con `Expanded`, `Flexible` y `Column`/`Row` responsivos.

Se ejecutan pruebas de widgets del catálogo a 320 y 700 píxeles lógicos con escalas
de texto 1.0 y 2.0, sin excepciones de layout. Se verifica además el tamaño mínimo
48x48 de AppButton y que las etiquetas no estén limitadas a una línea con elipsis.
Estas pruebas no sustituyen la comprobación física completa ni el lector de pantalla.

## 10. Registro de uso de inteligencia artificial

Se utilizó GitHub Copilot como herramienta de asistencia para:

- inspección del proyecto real
- revisión del backend y de la API existente
- implementación del sistema de diseño
- creación de componentes reutilizables
- integración con la pantalla real
- corrección de errores de compilación/análisis
- elaboración y actualización de la documentación técnica

## 11. Evidencias para el PDF

Para construir el informe final en PDF se recomienda tomar capturas de:

1. `HomeScreen` con la vista principal de gastos.
2. La vista de login (pantalla sin usuario).
3. El estado de sincronización y diagnóstico de API.
4. El catálogo de componentes reutilizables.
5. La vista de estado vacío.
6. La vista de error o estado cargando.
7. El archivo `cashcontrol_theme.dart` mostrando tokens.

Estas capturas deben acompañarse del código fuente real que quedó en la carpeta `mobile/lib`.

## 12. Verificación y evidencia manual

Comandos de comprobación: `flutter analyze` y `flutter test`. La instalación se
realiza como actualización en el Android físico, sin desinstalar ni purgar SQLite.
Las pruebas automatizadas cubren contraste, carga, vacío, ajuste a dos anchos y
texto ampliado. El resultado y la instalación de la revisión actual deben
acompañarse de las evidencias de ejecución, no solo del código.

Resultado de la revisión del 2 de octubre de 2026: `flutter analyze` sin problemas,
12 pruebas Flutter aprobadas, APK debug compilado e instalado correctamente en
SM A715F mediante actualización. La actividad abrió y la API desde el teléfono
respondió `database: CONNECTED`. Hot reload completado en 931 ms; no había
bibliotecas pendientes de cambio tras la instalación.

Comprobación manual de TalkBack: el usuario confirmó el 2 de octubre de 2026
haber realizado el recorrido en el teléfono. Esta evidencia es una confirmación
humana, no una prueba automatizada ni una certificación completa de WCAG 2.2.
Para conservar la evidencia del informe se recomienda adjuntar la captura o
grabación del recorrido y sus observaciones. Las pruebas automáticas de dos
anchos y fuente ampliada se documentan por separado.
