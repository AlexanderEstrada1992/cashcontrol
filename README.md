# CashControl

CashControl es una aplicación móvil multiplataforma orientada a la gestión de finanzas personales. Su objetivo es permitir que los usuarios puedan registrar y controlar ingresos, gastos y presupuestos mediante una aplicación móvil conectada a un backend propio y una base de datos relacional.

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
* Emulador Pixel 5
* Android 15 – API 35
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

El entorno Android se encuentra configurado correctamente con Android SDK, emulador y licencias aceptadas.

El diagnóstico puede mostrar una advertencia relacionada con Visual Studio para desarrollo de aplicaciones Windows. Esta advertencia no afecta al proyecto, debido a que CashControl se ejecuta actualmente sobre Android.

## Ejecución del emulador

El proyecto utiliza un emulador Pixel 5 con Android 15 API 35.

Para verificar los dispositivos disponibles:

```bash
flutter devices
```

El emulador utilizado aparece como:

```text
emulator-5554
Android 15 (API 35)
```

## Ejecución de la aplicación Flutter

Desde la carpeta `mobile`:

```bash
flutter pub get
flutter run -d emulator-5554
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

Debido a que la aplicación se ejecuta en un emulador Android, no se utiliza `localhost` para acceder al backend de Windows.

La dirección utilizada es:

```text
http://10.0.2.2:3000
```

`10.0.2.2` permite que el emulador Android acceda al host donde se ejecuta Node.js.

La URL base se configura en Flutter mediante:

```dart
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000',
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
