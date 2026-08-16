# Plan Completo: CashControl - Aplicación de Gestión de Finanzas Personales

**Versión:** 1.0  
**Fecha:** 2026-08-16  
**Estado:** Planificación en revisión

---

## ÍNDICE
1. Evaluación del Repositorio Actual
2. Arquitectura Propuesta
3. Estructura de Directorios
4. Tecnologías y Dependencias
5. Modelo Lógico de Base de Datos
6. Recursos y Endpoints de la API
7. Estrategia de Autenticación y Autorización
8. Estrategia de Roles y Propiedad de Recursos
9. Estrategia de Seguridad
10. Estrategia de Validaciones y Manejo de Errores
11. Estrategia de Pruebas
12. Estrategia de Optimización
13. Estrategia de Documentación
14. Estrategia de Ramas y Commits
15. Plan de Implementación Progresivo (Etapas)
16. Riesgos Técnicos y Mitigación
17. Dependencias Externas Requeridas
18. Criterios de Finalización por Fase
19. Primera Tarea de Implementación (Sin Ejecutar)

---

## 1. EVALUACIÓN DEL REPOSITORIO ACTUAL

**Estado:** ✓ ÓPTIMO PARA INICIO

- ✓ Git inicializado correctamente
- ✓ .gitignore ya contiene patrones Flutter (reutilizable)
- ✓ README.md básico (será expandido)
- ✓ Estructura de directorios vacía (limpia, sin conflictos)
- ✓ No existen archivos que interfieran con la nueva arquitectura

**Acciones previas:** Ninguna. Comenzamos desde cero de forma limpia.

---

## 2. ARQUITECTURA PROPUESTA

### 2.1 Diagrama General

```
┌─────────────────────────────────────────────────────────────┐
│                    CAPA DE PRESENTACIÓN                      │
│                   (Flutter Mobile App)                       │
│  • Android / iOS / Web (opcional)                            │
│  • State Management (Provider/Riverpod)                      │
│  • Validaciones en tiempo real                               │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTP/HTTPS + JWT
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                   CAPA DE API & LÓGICA                       │
│              (Node.js + Express.js)                          │
│  • REST API estandarizada                                    │
│  • Middleware de autenticación/autorización                  │
│  • Validaciones de negocio                                   │
│  • Gestión de errores centralizada                           │
│  • Caché (Redis - opcional pero recomendado)                │
└────────────────────┬────────────────────────────────────────┘
                     │ node-oracledb (consultas parametrizadas)
                     ↓
┌─────────────────────────────────────────────────────────────┐
│                  CAPA DE DATOS                               │
│            (Oracle Database en Docker)                       │
│  • Tablas normalizadas (3FN)                                 │
│  • Integridad referencial                                    │
│  • Índices estratégicos                                      │
│  • Restricciones y validaciones                              │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Principios de Diseño

- **Separación de responsabilidades:** Cada capa independiente
- **Escalabilidad:** Backend preparado para múltiples clientes
- **Seguridad:** Defensa en profundidad (BD → API → Cliente)
- **Testabilidad:** Componentes desacoplados
- **Mantenibilidad:** Clean code y patrones SOLID

---

## 3. ESTRUCTURA DE DIRECTORIOS PROPUESTA

```
cashcontrol/
├── .github/
│   └── workflows/                          # CI/CD (futura)
├── docs/
│   ├── ARQUITECTURA.md
│   ├── BASE_DE_DATOS.md
│   ├── API.md
│   ├── SEGURIDAD.md
│   ├── OPTIMIZACION.md
│   ├── GUIA_INSTALACION.md
│   └── EVIDENCIAS/                         # Evidencias académicas
├── mobile/                                  # Frontend Flutter
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/
│   │   │   ├── constants.dart
│   │   │   ├── themes.dart
│   │   │   └── api_config.dart
│   │   ├── models/
│   │   │   ├── usuario.dart
│   │   │   ├── ingreso.dart
│   │   │   ├── gasto.dart
│   │   │   ├── categoria.dart
│   │   │   ├── presupuesto.dart
│   │   │   └── reporte.dart
│   │   ├── providers/                      # State management
│   │   │   ├── auth_provider.dart
│   │   │   ├── usuario_provider.dart
│   │   │   ├── ingreso_provider.dart
│   │   │   ├── gasto_provider.dart
│   │   │   ├── categoria_provider.dart
│   │   │   ├── presupuesto_provider.dart
│   │   │   └── reporte_provider.dart
│   │   ├── services/
│   │   │   ├── api_service.dart
│   │   │   ├── auth_service.dart
│   │   │   └── storage_service.dart
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── registro_screen.dart
│   │   │   ├── main/
│   │   │   │   ├── dashboard_screen.dart
│   │   │   │   ├── ingresos_screen.dart
│   │   │   │   ├── gastos_screen.dart
│   │   │   │   ├── categorias_screen.dart
│   │   │   │   ├── presupuestos_screen.dart
│   │   │   │   ├── historial_screen.dart
│   │   │   │   ├── reportes_screen.dart
│   │   │   │   └── perfil_screen.dart
│   │   ├── widgets/
│   │   │   ├── custom_appbar.dart
│   │   │   ├── error_widget.dart
│   │   │   ├── loading_widget.dart
│   │   │   └── transaccion_card.dart
│   │   └── utils/
│   │       ├── validators.dart
│   │       ├── formatters.dart
│   │       └── dialogs.dart
│   ├── test/
│   ├── pubspec.yaml
│   ├── pubspec.lock
│   ├── .env.example
│   └── README.md
│
├── backend/                                 # API Node.js + Express
│   ├── src/
│   │   ├── config/
│   │   │   ├── database.js
│   │   │   ├── redis.js
│   │   │   └── environment.js
│   │   ├── models/
│   │   │   ├── usuario.js
│   │   │   ├── categoria.js
│   │   │   ├── ingreso.js
│   │   │   ├── gasto.js
│   │   │   ├── presupuesto.js
│   │   │   └── queries.js                  # Consultas SQL complejas
│   │   ├── controllers/
│   │   │   ├── auth.controller.js
│   │   │   ├── usuario.controller.js
│   │   │   ├── categoria.controller.js
│   │   │   ├── ingreso.controller.js
│   │   │   ├── gasto.controller.js
│   │   │   ├── presupuesto.controller.js
│   │   │   └── reporte.controller.js
│   │   ├── routes/
│   │   │   ├── auth.routes.js
│   │   │   ├── usuario.routes.js
│   │   │   ├── categoria.routes.js
│   │   │   ├── ingreso.routes.js
│   │   │   ├── gasto.routes.js
│   │   │   ├── presupuesto.routes.js
│   │   │   ├── reporte.routes.js
│   │   │   └── index.js
│   │   ├── middleware/
│   │   │   ├── auth.middleware.js
│   │   │   ├── authorization.middleware.js
│   │   │   ├── validation.middleware.js
│   │   │   ├── errorHandler.middleware.js
│   │   │   └── rateLimit.middleware.js
│   │   ├── services/
│   │   │   ├── auth.service.js
│   │   │   ├── usuario.service.js
│   │   │   ├── ingreso.service.js
│   │   │   ├── gasto.service.js
│   │   │   ├── presupuesto.service.js
│   │   │   ├── reporte.service.js
│   │   │   ├── cache.service.js
│   │   │   ├── token.service.js
│   │   │   └── notification.service.js
│   │   ├── validators/
│   │   │   ├── auth.validator.js
│   │   │   ├── usuario.validator.js
│   │   │   ├── transaccion.validator.js
│   │   │   ├── presupuesto.validator.js
│   │   │   └── common.validator.js
│   │   ├── utils/
│   │   │   ├── response.js
│   │   │   ├── errors.js
│   │   │   ├── logger.js
│   │   │   └── encryption.js
│   │   ├── queue/                          # Procesamiento asíncrono
│   │   │   ├── reportQueue.js
│   │   │   ├── notificationQueue.js
│   │   │   └── workers.js
│   │   └── app.js                          # Punto de entrada principal
│   ├── database/
│   │   └── schemas/
│   │       ├── 01-create-tables.sql
│   │       ├── 02-create-indexes.sql
│   │       ├── 03-insert-initial-data.sql
│   │       └── 04-seed-categories.sql
│   ├── tests/
│   │   ├── integration/                    # Pruebas Postman/API
│   │   ├── unit/
│   │   └── postman/
│   │       └── CashControl.postman_collection.json
│   ├── .env.example
│   ├── .env                                # NO VERSIONAR (en .gitignore)
│   ├── package.json
│   ├── package-lock.json
│   ├── .gitignore
│   ├── README.md
│   └── server.js                           # Entry point
│
├── .gitignore                              # Ya existe (mejorar)
├── README.md                               # Ya existe (expandir)
└── .git/
```

---

## 4. TECNOLOGÍAS Y DEPENDENCIAS

### 4.1 Backend (Node.js)

**Dependencias principales:**
```
express@4.18.2                              # Framework web
node-oracledb@6.x                           # Driver Oracle
dotenv@16.3.1                               # Gestión .env
bcryptjs@2.4.3 o argon2@0.31.1             # Hash contraseñas
jsonwebtoken@9.1.0                          # JWT
joi@17.x                                    # Validaciones
cors@2.8.5                                  # CORS
helmet@7.0.0                                # Seguridad headers
express-rate-limit@7.0.0                    # Rate limiting
redis@4.x (opcional pero recomendado)       # Caché
bull@4.x (opcional)                         # Cola de trabajo
swagger-jsdoc@6.2.8                         # Swagger generación
swagger-ui-express@5.0.0                    # Swagger UI
compression@1.7.4                           # Compresión
morgan@1.10.0                               # Logging HTTP
```

**Dependencias desarrollo:**
```
nodemon@3.0.1                               # Auto-reload
jest@29.x                                   # Testing
supertest@6.x                               # HTTP testing
```

### 4.2 Mobile (Flutter)

**Dependencias principales:**
```
http@1.1.0                                  # HTTP requests
provider@6.0.0                              # State management
flutter_secure_storage@9.0.0                # Almacenamiento seguro
shared_preferences@2.2.0                    # Preferences locales
intl@0.18.0                                 # Internacionalización
dio@5.3.0                                   # HTTP alternativa
fl_chart@0.63.0                             # Gráficos
curved_navigation_bar@1.0.3                 # UI
getit@7.5.0                                 # Service locator
equatable@2.0.5                             # Equality utility
```

### 4.3 Base de Datos

**Oracle Database:**
- Oracle Database XE (Express Edition) vía Docker
- Conexión con node-oracledb (nativo)
- SQL Developer para administración

**Redis (opcional pero recomendado):**
- Caché de consultas frecuentes
- Sesiones de usuario
- Rate limiting
- Datos transitorios

### 4.4 Herramientas Externas

- **Docker & Docker Compose:** Orquestación de contenedores
- **Git:** Control de versiones (ya disponible)
- **Postman:** Testing de API
- **Oracle SQL Developer:** Administración BD
- **VS Code:** Editor principal
- **Android Studio / Xcode:** Emuladores (opcional)

---

## 5. MODELO LÓGICO DE BASE DE DATOS

### 5.1 Entidades Principales

#### USUARIO
```
ID_USUARIO          NUMBER PRIMARY KEY
CORREO              VARCHAR2(100) UNIQUE NOT NULL
CONTRASEÑA_HASH     VARCHAR2(255) NOT NULL
NOMBRE              VARCHAR2(100) NOT NULL
APELLIDO            VARCHAR2(100) NOT NULL
FECHA_NACIMIENTO    DATE
TELEFONO            VARCHAR2(20)
MONEDA_PREDEFINIDA  VARCHAR2(3) DEFAULT 'USD'
ROL                 VARCHAR2(20) DEFAULT 'USUARIO' NOT NULL
ESTADO              VARCHAR2(20) DEFAULT 'ACTIVO' NOT NULL
FECHA_CREACION      TIMESTAMP DEFAULT SYSTIMESTAMP
FECHA_ACTUALIZACION TIMESTAMP DEFAULT SYSTIMESTAMP
ULTIMO_ACCESO       TIMESTAMP
```

#### CATEGORIA
```
ID_CATEGORIA        NUMBER PRIMARY KEY
NOMBRE              VARCHAR2(50) NOT NULL
DESCRIPCION         VARCHAR2(255)
TIPO                VARCHAR2(20) NOT NULL (INGRESO | GASTO)
COLOR_HEX           VARCHAR2(7)
ICONO_NOMBRE        VARCHAR2(50)
ACTIVO              CHAR(1) DEFAULT 'S' NOT NULL
ES_GLOBAL           CHAR(1) DEFAULT 'S' NOT NULL
ID_USUARIO_CREADOR  NUMBER (NULL si es global)
FECHA_CREACION      TIMESTAMP DEFAULT SYSTIMESTAMP
UNIQUE(NOMBRE, TIPO, ID_USUARIO_CREADOR)
FOREIGN KEY (ID_USUARIO_CREADOR) REFERENCES USUARIO(ID_USUARIO)
```

#### INGRESO
```
ID_INGRESO          NUMBER PRIMARY KEY
ID_USUARIO          NUMBER NOT NULL
ID_CATEGORIA        NUMBER NOT NULL
MONTO               NUMBER(12,2) NOT NULL (> 0)
DESCRIPCION         VARCHAR2(255)
FECHA_INGRESO       DATE NOT NULL
TIPO_INGRESO        VARCHAR2(20) (SALARIO | BONIFICACION | OTRO)
REFERENCIA          VARCHAR2(100)
RECURRENTE          CHAR(1) DEFAULT 'N'
FRECUENCIA          VARCHAR2(20) (DIARIA | SEMANAL | MENSUAL | ANUAL)
FECHA_CREACION      TIMESTAMP DEFAULT SYSTIMESTAMP
FECHA_ACTUALIZACION TIMESTAMP DEFAULT SYSTIMESTAMP
FOREIGN KEY (ID_USUARIO) REFERENCES USUARIO(ID_USUARIO)
FOREIGN KEY (ID_CATEGORIA) REFERENCES CATEGORIA(ID_CATEGORIA)
CHECK (MONTO > 0)
```

#### GASTO
```
ID_GASTO            NUMBER PRIMARY KEY
ID_USUARIO          NUMBER NOT NULL
ID_CATEGORIA        NUMBER NOT NULL
MONTO               NUMBER(12,2) NOT NULL (> 0)
DESCRIPCION         VARCHAR2(255)
FECHA_GASTO         DATE NOT NULL
TIPO_GASTO          VARCHAR2(20) (ESENCIAL | DISCRECIONAL | INVERSIÓN)
REFERENCIA          VARCHAR2(100)
RECURRENTE          CHAR(1) DEFAULT 'N'
FRECUENCIA          VARCHAR2(20) (DIARIA | SEMANAL | MENSUAL | ANUAL)
PAGADO              CHAR(1) DEFAULT 'S'
FECHA_CREACION      TIMESTAMP DEFAULT SYSTIMESTAMP
FECHA_ACTUALIZACION TIMESTAMP DEFAULT SYSTIMESTAMP
FOREIGN KEY (ID_USUARIO) REFERENCES USUARIO(ID_USUARIO)
FOREIGN KEY (ID_CATEGORIA) REFERENCES CATEGORIA(ID_CATEGORIA)
CHECK (MONTO > 0)
```

#### PRESUPUESTO
```
ID_PRESUPUESTO      NUMBER PRIMARY KEY
ID_USUARIO          NUMBER NOT NULL
MONTO_LIMITE        NUMBER(12,2) NOT NULL (> 0)
MES                 NUMBER(2) NOT NULL (1-12)
AÑO                 NUMBER(4) NOT NULL
DESCRIPCION         VARCHAR2(255)
ALERTA_PORCENTAJE   NUMBER(3) DEFAULT 80 (20-100)
ESTADO              VARCHAR2(20) DEFAULT 'ACTIVO'
FECHA_CREACION      TIMESTAMP DEFAULT SYSTIMESTAMP
FECHA_ACTUALIZACION TIMESTAMP DEFAULT SYSTIMESTAMP
FOREIGN KEY (ID_USUARIO) REFERENCES USUARIO(ID_USUARIO)
UNIQUE(ID_USUARIO, MES, AÑO)
CHECK (MONTO_LIMITE > 0)
CHECK (ALERTA_PORCENTAJE BETWEEN 20 AND 100)
```

#### REFRESH_TOKEN_REVOKED (Gestión de tokens)
```
ID_TOKEN_REVOKED    NUMBER PRIMARY KEY
ID_USUARIO          NUMBER NOT NULL
REFRESH_TOKEN_HASH  VARCHAR2(255) NOT NULL
FECHA_REVOCACION    TIMESTAMP DEFAULT SYSTIMESTAMP
RAZON               VARCHAR2(100)
FOREIGN KEY (ID_USUARIO) REFERENCES USUARIO(ID_USUARIO)
```

### 5.2 Índices Estratégicos

```
Tabla USUARIO:
  - IDX_USUARIO_CORREO ON USUARIO(CORREO)
  - IDX_USUARIO_ROL ON USUARIO(ROL)
  - IDX_USUARIO_ESTADO ON USUARIO(ESTADO)

Tabla INGRESO:
  - IDX_INGRESO_USUARIO_FECHA ON INGRESO(ID_USUARIO, FECHA_INGRESO)
  - IDX_INGRESO_CATEGORIA ON INGRESO(ID_CATEGORIA)
  - IDX_INGRESO_USUARIO_MES ON INGRESO(ID_USUARIO, TRUNC(FECHA_INGRESO,'MM'))

Tabla GASTO:
  - IDX_GASTO_USUARIO_FECHA ON GASTO(ID_USUARIO, FECHA_GASTO)
  - IDX_GASTO_CATEGORIA ON GASTO(ID_CATEGORIA)
  - IDX_GASTO_USUARIO_MES ON GASTO(ID_USUARIO, TRUNC(FECHA_GASTO,'MM'))
  - IDX_GASTO_PAGADO ON GASTO(PAGADO)

Tabla PRESUPUESTO:
  - IDX_PRESUPUESTO_USUARIO_MES ON PRESUPUESTO(ID_USUARIO, MES, AÑO)
  - IDX_PRESUPUESTO_ESTADO ON PRESUPUESTO(ESTADO)

Tabla CATEGORIA:
  - IDX_CATEGORIA_TIPO ON CATEGORIA(TIPO)
  - IDX_CATEGORIA_ACTIVO ON CATEGORIA(ACTIVO)
```

### 5.3 Entidades Adicionales Consideradas

- **AUDIT_LOG:** Para rastrear cambios en datos sensibles (futura)
- **NOTIFICACION:** Para alertas de presupuesto (puede implementarse en caché)
- **CUENTA_BANCARIA:** Para proyecciones futuras (NO incluida inicialmente)

**Decisión:** Se comienza con las 5 entidades principales. Las adicionales se crearán solo si se justifican en futuras iteraciones.

---

## 6. RECURSOS Y ENDPOINTS DE LA API

### 6.1 Estructuras de Respuesta Estandarizadas

**Respuesta exitosa:**
```json
{
  "success": true,
  "message": "Operación realizada correctamente",
  "data": {},
  "meta": {
    "timestamp": "2026-08-16T10:30:00Z",
    "version": "1.0"
  }
}
```

**Respuesta con error:**
```json
{
  "success": false,
  "message": "No fue posible procesar la solicitud",
  "errors": [
    {
      "field": "correo",
      "message": "El correo ya está registrado",
      "code": "DUPLICATE_ENTRY"
    }
  ],
  "meta": {
    "timestamp": "2026-08-16T10:30:00Z",
    "version": "1.0"
  }
}
```

**Respuesta paginada:**
```json
{
  "success": true,
  "message": "Registros obtenidos",
  "data": [],
  "pagination": {
    "page": 1,
    "pageSize": 10,
    "totalRecords": 45,
    "totalPages": 5
  }
}
```

### 6.2 Endpoints Principales por Recurso

#### AUTENTICACIÓN (Base: `/api/v1/auth`)
```
POST   /registro              - Registro nuevo usuario
POST   /login                 - Inicio de sesión
POST   /refresh-token         - Renovar access token
POST   /logout                - Cierre de sesión
POST   /revoke-token          - Revocar refresh token
POST   /forgot-password       - Solicitar reset contraseña (futura)
```

#### USUARIOS (Base: `/api/v1/usuarios`)
```
GET    /                      - Listar usuarios (ADMIN only)
GET    /:id                   - Obtener perfil (propio o ADMIN)
PUT    /:id                   - Actualizar perfil
DELETE /:id                   - Eliminar cuenta (propio o ADMIN)
POST   /:id/cambiar-password  - Cambiar contraseña
GET    /:id/resumen           - Resumen financiero del usuario
```

#### CATEGORÍAS (Base: `/api/v1/categorias`)
```
GET    /                      - Listar categorías (propias + globales)
GET    /:id                   - Obtener categoría
POST   /                      - Crear categoría (USUARIO | ADMIN)
PUT    /:id                   - Actualizar categoría
DELETE /:id                   - Eliminar categoría
GET    /tipos/valores         - Valores enum de tipos
```

#### INGRESOS (Base: `/api/v1/ingresos`)
```
GET    /                      - Listar ingresos (paginado, filtrable)
GET    /:id                   - Obtener ingreso específico
POST   /                      - Registrar nuevo ingreso
PUT    /:id                   - Actualizar ingreso
DELETE /:id                   - Eliminar ingreso
GET    /usuario/:usuarioId    - Historial de ingresos de usuario
GET    /estadisticas/total    - Totales por categoría/mes
```

#### GASTOS (Base: `/api/v1/gastos`)
```
GET    /                      - Listar gastos (paginado, filtrable)
GET    /:id                   - Obtener gasto específico
POST   /                      - Registrar nuevo gasto
PUT    /:id                   - Actualizar gasto
DELETE /:id                   - Eliminar gasto
GET    /usuario/:usuarioId    - Historial de gastos de usuario
GET    /estadisticas/total    - Totales por categoría/mes/tipo
GET    /presupuesto/alerta    - Gastos que superan presupuesto
```

#### PRESUPUESTOS (Base: `/api/v1/presupuestos`)
```
GET    /                      - Listar presupuestos del usuario
GET    /:id                   - Obtener presupuesto específico
POST   /                      - Crear presupuesto
PUT    /:id                   - Actualizar presupuesto
DELETE /:id                   - Eliminar presupuesto
GET    /:id/estado            - Estado actual vs presupuesto
GET    /:id/detalle           - Desglose de gastos vs presupuesto
```

#### REPORTES (Base: `/api/v1/reportes`)
```
GET    /resumen-mes           - Resumen mensuales (entrada/salida)
GET    /resumen-año           - Resumen anual
GET    /gasto-por-categoria   - Distribución de gastos
GET    /ingreso-por-categoria - Distribución de ingresos
GET    /tendencia             - Tendencias (últimos N meses)
GET    /comparativa           - Comparativa mes anterior
POST   /generar-pdf           - Generar reporte PDF (asincrónico)
POST   /generar-excel         - Generar reporte Excel (asincrónico)
```

#### ADMINISTRACIÓN (Base: `/api/v1/admin`)
```
GET    /usuarios              - Listar todos usuarios (con estadísticas)
DELETE /usuarios/:id          - Eliminar usuario (fuerza)
POST   /categorias            - Crear categoría global
PUT    /categorias/:id        - Actualizar categoría global
DELETE /categorias/:id        - Eliminar categoría global
GET    /auditoria             - Log de cambios (futura)
```

### 6.3 Parámetros de Query Comunes

```
page=1                        - Número de página (paginación)
limit=10                      - Registros por página
sort=fecha_creacion           - Campo para ordenar
order=DESC                    - ASC | DESC
search=texto                  - Búsqueda general
categoria=1,2,3               - Filtro por categorías
fechaInicio=2026-01-01        - Filtro rango fechas
fechaFin=2026-08-31
tipo=GASTO                    - Filtro por tipo
estado=ACTIVO                 - Filtro por estado
```

---

## 7. ESTRATEGIA DE AUTENTICACIÓN Y AUTORIZACIÓN

### 7.1 Flujo JWT Completo

**Registro:**
1. Usuario envía: correo, contraseña, nombre, apellido
2. Backend valida y hashea contraseña con bcryptjs (rounds: 12) o Argon2
3. Se crea registro en tabla USUARIO con rol='USUARIO'
4. Respuesta: usuario creado (sin datos sensibles)

**Login:**
1. Usuario envía: correo, contraseña
2. Backend busca usuario, compara contraseña
3. Si válido: genera tokens
   - **Access Token:** JWT firmado, 15 minutos, contiene: {userId, rol, email}
   - **Refresh Token:** JWT firmado, 7 días, contiene: {userId, tokenVersion}
4. Refresh token se almacena hasheado en REFRESH_TOKEN_REVOKED (para revocación)
5. Respuesta: {accessToken, refreshToken, usuario}

**Refresh Token:**
1. Cliente envía refresh token
2. Backend valida: firma, expiración, no está revocado
3. Genera nuevo access token
4. Respuesta: {accessToken, refreshToken (opcional)}

**Logout:**
1. Backend registra invalidación del refresh token en REFRESH_TOKEN_REVOKED
2. Cliente elimina tokens locales

### 7.2 Middleware de Autenticación

```javascript
// verifyToken middleware
- Extrae token del header Authorization: Bearer <token>
- Valida firma y expiración
- Extrae datos: userId, rol, email
- Adjunta a req.user
- Si falla: 401 Unauthorized
```

### 7.3 Middleware de Autorización

```javascript
// authorize(rolesPermitidos) middleware
- Verifica req.user.rol está en rolesPermitidos
- Si falla: 403 Forbidden
```

### 7.4 Verificación de Propiedad de Recursos

```javascript
// verifyResourceOwnership middleware
- Para recursos como ingresos, gastos, presupuestos
- Valida que req.user.userId === recurso.id_usuario
- ADMINS pueden ver todo (según configuración)
- Si falla: 403 Forbidden
```

### 7.5 Almacenamiento de Tokens en Cliente (Flutter)

```
- Access Token: En memoria (se pierde al cerrar app)
- Refresh Token: flutter_secure_storage (encriptado)
- Último usuario: SharedPreferences
```

### 7.6 Gestión de Sesiones

- Cada usuario puede tener múltiples sesiones (múltiples dispositivos)
- Cada refresh token es único e independiente
- Revocación individual de tokens (sin afectar otras sesiones)

---

## 8. ESTRATEGIA DE ROLES Y PROPIEDAD DE RECURSOS

### 8.1 Matriz de Permisos

| Acción | USUARIO | ADMIN |
|--------|---------|-------|
| Ver su perfil | ✓ | ✓ (+ otros) |
| Editar su perfil | ✓ | ✓ (+ otros) |
| Ver sus ingresos | ✓ | ✗ |
| Crear ingresos | ✓ | ✗ |
| Ver otros ingresos | ✗ | ✗* |
| Crear categoría personal | ✓ | ✓ |
| Crear categoría global | ✗ | ✓ |
| Listar usuarios | ✗ | ✓ |
| Eliminar usuario | ✗ | ✓ |
| Ver reportes propios | ✓ | ✓ (+ otros) |
| Acceder panel admin | ✗ | ✓ |

*ADMIN accede a datos de usuarios solo por razones administrativas (auditoría), nunca automáticamente a ingresos/gastos.

### 8.2 Validación de Propiedad

**Antes de cada operación READ/UPDATE/DELETE:**

```
IF requester.rol == 'ADMIN' THEN
  ALLOW (para auditoría)
ELSE IF requester.userId == recurso.id_usuario THEN
  ALLOW
ELSE
  RETURN 403 Forbidden
END IF
```

### 8.3 Niveles de Acceso Progresivo

```
Nivel 1: No autenticado → 401 Unauthorized
Nivel 2: Usuario + Propiedad → 200 OK o 403 Forbidden
Nivel 3: Admin únicamente → 200 OK o 403 Forbidden
```

---

## 9. ESTRATEGIA DE SEGURIDAD

### 9.1 Almacenamiento Seguro

**Contraseñas:**
- Hash con bcryptjs (rounds: 12) O Argon2
- Nunca almacenar plaintext
- Nunca retornar hash al cliente

**Tokens JWT:**
- Firmados con SECRET_KEY (en .env)
- SECRET_KEY mínimo 32 caracteres aleatorios
- Refresh tokens hasheados en BD

**Variables sensibles:**
- Todas en `.env` (no versionado)
- `.env.example` con placeholders

### 9.2 Validación y Sanitización

**Validación de entrada:**
- Usar librería `joi` para esquemas
- Validar tipo, longitud, formato
- Rechazar datos innecesarios

**Sanitización:**
- Escapar caracteres especiales (aunque usamos queries parametrizadas)
- Limitar longitud de strings
- No permitir objetos anidados no esperados

### 9.3 Prevención de SQL Injection

- **Siempre usar queries parametrizadas** con node-oracledb
- Nunca concatenar inputs directamente a SQL
- Ejemplo correcto:
  ```javascript
  const result = await connection.execute(
    'SELECT * FROM USUARIO WHERE ID_USUARIO = :userId',
    { userId: req.user.userId }
  );
  ```

### 9.4 CORS (Cross-Origin Resource Sharing)

```javascript
const corsOptions = {
  origin: process.env.FRONTEND_URL,  // ej: http://localhost:3000
  credentials: true,
  optionsSuccessStatus: 200
};
app.use(cors(corsOptions));
```

### 9.5 Rate Limiting

- Endpoints públicos (login, registro): 5 intentos / 15 minutos
- API general: 100 requests / minuto por usuario
- Uso de `express-rate-limit` con Redis (opcional)

### 9.6 Seguridad de Headers

- **Helmet.js:** Protección contra vulnerabilidades comunes
  - X-Frame-Options: DENY
  - X-Content-Type-Options: nosniff
  - X-XSS-Protection: 1; mode=block
  - Strict-Transport-Security: max-age=31536000 (HTTPS)

### 9.7 Manejo de Errores Seguro

**NO exponer:**
- Stack traces
- Detalles de BD
- Rutas de archivos
- Información de dependencias

**Responder:**
```json
{
  "success": false,
  "message": "Error al procesar solicitud",
  "errors": [
    { "message": "Validación fallida", "code": "VALIDATION_ERROR" }
  ]
}
```

### 9.8 HTTPS

- Obligatorio en producción
- Certificados SSL/TLS
- Redirección HTTP → HTTPS
- HSTS headers

### 9.9 Logging Seguro

- No registrar: contraseñas, tokens, datos sensibles
- Registrar: acciones de usuario, cambios críticos, errores
- Usar librería `winston` o `pino`

---

## 10. ESTRATEGIA DE VALIDACIONES Y MANEJO DE ERRORES

### 10.1 Niveles de Validación

**Nivel 1: Cliente (Flutter)**
- Validación en tiempo real
- Feedback inmediato al usuario
- Mejora UX

**Nivel 2: API (Node.js)**
- Validación completa de entrada
- Validación de reglas de negocio
- Validación de autorización

**Nivel 3: Base de Datos**
- Restricciones SQL (NOT NULL, UNIQUE, CHECK)
- Integridad referencial
- Última línea de defensa

### 10.2 Códigos HTTP Correctos

```
200 OK                    - Solicitud exitosa
201 Created               - Recurso creado
204 No Content            - Éxito sin contenido (DELETE)
400 Bad Request           - Datos inválidos del cliente
401 Unauthorized          - Autenticación requerida / falló
403 Forbidden             - Autorización fallida / Propiedad
404 Not Found             - Recurso no existe
409 Conflict              - Datos duplicados o conflicto
422 Unprocessable Entity  - Validación de negocio fallida
500 Internal Server Error - Error del servidor
503 Service Unavailable   - BD no disponible
```

### 10.3 Objeto de Error Estandarizado

```javascript
{
  field: "correo",              // Campo problemático (opcional)
  message: "El correo es inválido",  // Mensaje legible
  code: "INVALID_EMAIL",        // Código de error
  value: "invalid-email"        // Valor rechazado (opcional)
}
```

### 10.4 Validadores por Entidad

**USUARIO:**
- Correo: formato válido, longitud 5-100, único
- Contraseña: mínimo 8 caracteres, complejidad (mayús, minús, número, símbolo)
- Nombre/Apellido: 2-100 caracteres, sin caracteres especiales
- Teléfono: formato válido (opcional)

**INGRESO/GASTO:**
- Monto: número positivo, máximo 999,999.99
- Categoría: debe existir y ser accesible al usuario
- Fecha: no futura, no más antigua de 5 años
- Descripción: 0-255 caracteres

**PRESUPUESTO:**
- Monto: número positivo
- Mes/Año: valores válidos
- Alerta: 20-100

### 10.5 Middleware de Validación

```javascript
validate(schema) middleware
- Aplica esquema Joi
- Si hay errores: 400 + detalles
- Si válido: continúa
```

### 10.6 Manejo Centralizado de Errores

```javascript
// errorHandler.middleware.js
- Captura todos los errores
- Loguea (sin datos sensibles)
- Retorna respuesta estandarizada
- Separa errores esperados vs inesperados
```

---

## 11. ESTRATEGIA DE PRUEBAS

### 11.1 Tipos de Pruebas

**Pruebas Unitarias (Jest):**
- Funciones de validación
- Servicios de negocio
- Funciones de caché
- Cobertura mínima: 70%

**Pruebas de Integración (Postman/Newman):**
- Flujo completo: Registro → Login → CRUD → Logout
- Casos de error
- Autenticación/Autorización
- Paginación
- Filtros

**Pruebas Funcionales (Manual):**
- Flutter consumiendo API
- Flujos completos de usuario
- Casos edge
- Recuperación de errores

### 11.2 Colección Postman Estructurada

```
CashControl/
├── Auth/
│   ├── Registro exitoso
│   ├── Registro - Email duplicado (409)
│   ├── Registro - Contraseña débil (400)
│   ├── Login exitoso
│   ├── Login - Credenciales incorrectas (401)
│   ├── Refresh Token
│   ├── Refresh Token - Expirado (401)
│   └── Logout
├── Usuarios/
│   ├── Obtener perfil propio
│   ├── Obtener otros (403)
│   ├── Actualizar perfil
│   └── Cambiar contraseña
├── Categorías/
│   ├── Listar (propias + globales)
│   ├── Crear categoría personal
│   ├── Crear global (ADMIN only)
│   └── Eliminar
├── Ingresos/
│   ├── Listar (paginado)
│   ├── Listar - Filtrar por fecha
│   ├── Crear (sin token - 401)
│   ├── Crear - Monto inválido (422)
│   ├── Actualizar propio
│   ├── Actualizar otro (403)
│   └── Eliminar
├── Gastos/
│   ├── (Similar a Ingresos)
│   ├── Gasto que supera presupuesto (retorna advertencia)
│   └── Listar en periodo presupuestario
├── Presupuestos/
│   ├── Crear presupuesto
│   ├── Obtener estado
│   ├── Listar
│   └── Actualizar
├── Reportes/
│   ├── Resumen mensual
│   ├── Gasto por categoría
│   └── Tendencias
└── Admin/
    ├── Listar usuarios
    ├── Eliminar usuario
    └── Gestionar categorías globales
```

### 11.3 Criterios de Aceptación

- ✓ Todos los endpoints retornan JSON estandarizado
- ✓ Códigos HTTP correctos
- ✓ Autenticación requerida (excepto registro/login)
- ✓ Autorización funciona (usuarios ven solo sus datos)
- ✓ Validaciones rechazan datos inválidos
- ✓ Paginación funciona
- ✓ Filtros funciona
- ✓ Tokens expiran correctamente
- ✓ Refresh tokens se renuevan
- ✓ Logout revoca tokens

---

## 12. ESTRATEGIA DE OPTIMIZACIÓN

### 12.1 Paginación Obligatoria

**Implementación:**
```javascript
GET /api/v1/gastos?page=1&limit=10&sort=fecha_gasto&order=DESC

Respuesta:
{
  "data": [...],
  "pagination": {
    "page": 1,
    "pageSize": 10,
    "totalRecords": 245,
    "totalPages": 25
  }
}
```

**Límites:**
- Mínimo: 1
- Máximo: 100
- Default: 10

### 12.2 Filtros Estratégicos

**Gastos:**
```
- Por categoría: /gastos?categoria=1,2,3
- Por rango fecha: /gastos?fechaInicio=2026-01-01&fechaFin=2026-08-31
- Por tipo: /gastos?tipo=ESENCIAL
- Por mes/año: /gastos?mes=8&año=2026
```

**Ingresos:**
```
- Similar a gastos
- Por tipo: /ingresos?tipo=SALARIO
```

**Índices requeridos:**
- INGRESO(ID_USUARIO, FECHA_INGRESO)
- GASTO(ID_USUARIO, FECHA_GASTO)
- GASTO(CATEGORIA)
- PRESUPUESTO(ID_USUARIO, MES, AÑO)

### 12.3 Caché con Redis (Opcional pero Recomendado)

**Estrategia Cache-Aside:**

```javascript
GET /api/v1/usuarios/:id/resumen
1. Buscar en Redis: cache_key = 'resumen_usuario_' + userId
2. Si existe (TTL válido): retornar desde caché
3. Si no existe o expirado:
   a. Consultar BD (cálculos: suma ingresos, suma gastos)
   b. Guardar en Redis con TTL = 30 minutos
   c. Retornar
```

**Datos a cachear:**
- Resumen de usuario (ingresos/gastos totales)
- Categorías (globales, bajo cambio)
- Presupuestos del mes actual (cambia cada vez que hay gasto)

**TTL por tipo:**
- Categorías: 24 horas (cambios administrativos)
- Resumen usuario: 30 minutos (puede cambiar con cada transacción)
- Presupuestos: 1 hora

**Invalidación:**
```
Al crear/actualizar/eliminar un gasto:
- Invalidar: cache[resumen_usuario_X]
- Invalidar: cache[presupuesto_mes_X]
```

### 12.4 Problema N+1 y Solución

**Caso: Obtener ingresos del usuario con nombre de categoría**

**Situación ANTES (N+1):**
```sql
-- Query 1: Obtener ingresos
SELECT * FROM INGRESO WHERE ID_USUARIO = 1

-- Queries N: Para cada ingreso, obtener categoría
SELECT * FROM CATEGORIA WHERE ID_CATEGORIA = 1
SELECT * FROM CATEGORIA WHERE ID_CATEGORIA = 2
-- ... (N queries adicionales)
```
**Resultado:** 1 + N consultas (ineficiente)

**Solución CON JOIN:**
```sql
SELECT 
  i.ID_INGRESO,
  i.MONTO,
  i.DESCRIPCION,
  i.FECHA_INGRESO,
  c.NOMBRE as CATEGORIA_NOMBRE,
  c.COLOR_HEX
FROM INGRESO i
INNER JOIN CATEGORIA c ON i.ID_CATEGORIA = c.ID_CATEGORIA
WHERE i.ID_USUARIO = :userId
ORDER BY i.FECHA_INGRESO DESC
```
**Resultado:** 1 consulta (óptimo)

**Implementación en Node.js:**
```javascript
// queries.js
async function obtenerIngresosConCategoria(userId) {
  const sql = `
    SELECT i.*, c.NOMBRE as categoria_nombre
    FROM INGRESO i
    JOIN CATEGORIA c ON i.ID_CATEGORIA = c.ID_CATEGORIA
    WHERE i.ID_USUARIO = :userId
    ORDER BY i.FECHA_INGRESO DESC
  `;
  const result = await connection.execute(sql, { userId });
  return result.rows;
}
```

### 12.5 Lazy Loading vs Eager Loading

**LAZY LOADING (por defecto):**
```
GET /api/v1/gastos → Solo datos del gasto (ID, monto, fecha)
Cliente solicita: GET /api/v1/categorias/:id → Datos de categoría
```

**EAGER LOADING:**
```
GET /api/v1/gastos → Incluye categoria completa {nombre, color}
Justificación: Se necesita mostrar nombre en lista
```

**Decisión:** Eager loading en listados (para evitar requests adicionales), lazy loading en listados grandes (paginados > 50 registros).

### 12.6 Procesamiento Asincrónico

**Caso de uso:** Generar reportes en PDF/Excel

**SIN Asincronía (problemas):**
```
POST /api/v1/reportes/generar-pdf
- Genera informe (tarda 30+ segundos)
- Cliente espera timeout
```

**CON Asincronía (solución):**
```
POST /api/v1/reportes/generar-pdf
- Respuesta inmediata: {taskId: "xyz", status: "processing"}
- Proceso en background (queue + worker)
- GET /api/v1/reportes/tareas/:taskId
  - {status: "completed", url: "..."}

Implementación:
- Librería: Bull.js
- Broker: Redis
- Worker: Proceso separado
```

**Tareas asincrónicas propuestas:**
1. Generar reporte PDF/Excel
2. Enviar notificaciones de presupuesto (futura)
3. Procesar importaciones masivas (futura)

### 12.7 Optimización de Autenticación

**Problema:** Cada request valida token → consulta BD (redundante)

**Solución:**
```javascript
// En verifyToken middleware:
1. Decodificar JWT (sin BD)
2. Almacenar en memoria (req.user)
3. Solo si es CRÍTICO: validar sesión en BD/caché

// Redis cache de sesiones:
- key: 'session_' + userId
- value: {role, email, permisos}
- TTL: 30 minutos
- Invalidar en logout
```

**Resultado:** Reducir 1+ consultas por request → 0-1 consultas (caché)

---

## 13. ESTRATEGIA DE DOCUMENTACIÓN

### 13.1 Documentación de Código

**Swagger/OpenAPI:**
- Endpoint: `/api/docs`
- Incluye: esquemas, ejemplos, códigos respuesta
- Generación automática con `swagger-jsdoc`

**README.md por módulo:**
```
/backend/README.md        - Setup, ejecución, estructura
/mobile/README.md         - Setup, ejecución, estructura
/docs/ARQUITECTURA.md     - Diagrama sistemas
/docs/BASE_DE_DATOS.md    - Modelo ER, tablas, índices
/docs/API.md              - Endpoints, autenticación
/docs/SEGURIDAD.md        - Políticas, controles
/docs/OPTIMIZACION.md     - Estrategias, comparativas
/docs/GUIA_INSTALACION.md - Step-by-step setup
```

### 13.2 Documentación de Base de Datos

**Archivo SQL comentado:**
```sql
-- 01-create-tables.sql
-- Descripción de cada tabla
-- Relaciones, restricciones
```

**Diagrama ER (con herramienta como Lucidchart/Draw.io)**

### 13.3 Documentación de Seguridad

```
/docs/SEGURIDAD.md
- Hash de contraseñas
- JWT (tokens, refresh)
- CORS
- Rate limiting
- SQL Injection prevention
- Manejo de errores
- Variables de entorno
```

### 13.4 Documentación de Optimización

```
/docs/OPTIMIZACION.md
- Índices creados y justificación
- Problema N+1 identificado + solución
- Caché: qué, dónde, cuándo, TTL
- Paginación: límites, defaults
- Comparativa ANTES/DESPUÉS (queries, tiempos)
```

### 13.5 Postman Documentation

- Colección exportada: `CashControl.postman_collection.json`
- Environment: `CashControl.postman_environment.json`
- Incluye: ejemplos de requests/responses
- Documentación de cada endpoint

### 13.6 Evidencias Académicas

**Carpeta `/docs/EVIDENCIAS/`:**
```
├── Oracle-Docker-Running.png       # Oracle funcionando
├── SQLDeveloper-Connection.png     # Conexión SQL Developer
├── Tablas-Creadas.png              # Tablas en Oracle
├── Indices-Oracle.png              # Índices creados
├── Backend-Running.png             # Servidor Node.js
├── Swagger-UI.png                  # Swagger documentación
├── Postman-Tests.png               # Pruebas Postman
├── JWT-Token.png                   # Token JWT decodificado
├── Flutter-App.png                 # App Flutter en ejecución
├── Caché-Redis.png                 # Redis caché funcionando
├── Comparativa-Optimizacion.png    # Antes/después N+1
└── Git-Commits.png                 # Historial de commits
```

---

## 14. ESTRATEGIA DE RAMAS Y COMMITS

### 14.1 Estructura de Ramas

```
main/
  ↑ (PRs finales después de pruebas completas)
  │
  develop/
    ↑ (integración de features)
    │
    ├── feature/backend-setup
    ├── feature/database-schema
    ├── feature/auth-jwt
    ├── feature/crud-usuarios
    ├── feature/crud-ingresos
    ├── feature/crud-gastos
    ├── feature/crud-presupuestos
    ├── feature/reportes
    ├── feature/optimizacion
    ├── feature/swagger
    ├── feature/mobile-setup
    ├── feature/mobile-auth
    ├── feature/mobile-ingresos
    ├── feature/mobile-gastos
    ├── feature/mobile-presupuestos
    ├── feature/mobile-reportes
    ├── feature/mobile-integration
    └── bugfix/...

    hotfix/ (si fuera necesario)
```

### 14.2 Convención de Commits

```
Format: [TYPE] (SCOPE): Message

TYPE:
- feat: Nueva funcionalidad
- fix: Corrección de bug
- docs: Cambios en documentación
- style: Formato, sin cambios lógicos
- refactor: Reestructuración
- perf: Optimización de rendimiento
- test: Añadir/modificar pruebas

SCOPE: backend | mobile | database | docs

Message: Descripción clara, tiempo presente
- Máximo 72 caracteres
- Sin punto final

Ejemplos:
✓ feat(backend): add JWT authentication
✓ feat(database): create user and category tables
✓ fix(backend): prevent SQL injection in queries
✓ feat(mobile): implement login screen
✓ docs(backend): add API swagger documentation
✓ perf(backend): add indexes on frequently used columns
```

### 14.3 Workflow por Feature

1. `git checkout develop`
2. `git pull origin develop`
3. `git checkout -b feature/descripcion`
4. Desarrollo + commits incrementales
5. `git push origin feature/descripcion`
6. Crear Pull Request (descripción clara)
7. Revisión + ajustes
8. Merge a `develop`
9. Eliminar rama

---

## 15. PLAN DE IMPLEMENTACIÓN PROGRESIVO

### FASE 1: INFRAESTRUCTURA INICIAL
**Duración estimada:** 3-4 horas

#### 1.1 Estructura de Directorios
- Crear directorios: `/mobile`, `/backend`, `/docs`
- Actualizar README.md raíz
- Crear .gitignore mejorado para backend

#### 1.2 Configuración Git
- Crear ramas: `develop` y primeras `feature/*`
- Realizar primer commit: "Initial project structure"

#### 1.3 Documentación Base
- `/docs/ARQUITECTURA.md`
- `/docs/BASE_DE_DATOS.md` (preliminar)
- `/docs/GUIA_INSTALACION.md` (preliminar)

---

### FASE 2: BACKEND - CONFIGURACIÓN BASE
**Duración estimada:** 2-3 horas

#### 2.1 Proyecto Node.js
- `npm init` → `package.json`
- Instalar dependencias principales
- Crear estructura `/src` con carpetas base

#### 2.2 Configuración de Entorno
- `.env.example` con variables
- `config/environment.js`
- Variables: ORACLE_*, JWT_*, PORT, NODE_ENV

#### 2.3 Archivo Principal
- `server.js` (entry point)
- `src/app.js` (configuración Express)
- Middleware básico: cors, helmet, morgan
- Health check endpoint: `GET /health`

#### 2.4 Validación
- Ejecutar servidor sin errores
- Acceso a `GET /health` → 200 OK

#### 2.5 Evidencia y Commit
- Screenshot: servidor ejecutándose
- Commit: "feat(backend): initialize Node.js project"

---

### FASE 3: BASE DE DATOS - ORACLE
**Duración estimada:** 4-5 horas

#### 3.1 Oracle en Docker
- `docker-compose.yml` con Oracle XE
- Volume para persistencia
- Variables de entorno

#### 3.2 SQL Developer
- Conectar a Oracle
- Crear usuario de aplicación (cashcontrol_user)
- Establecer permisos

#### 3.3 Esquema de Tablas
- Crear tablas: USUARIO, CATEGORIA, INGRESO, GASTO, PRESUPUESTO, REFRESH_TOKEN_REVOKED
- Aplicar restricciones: PK, FK, CHECK, UNIQUE, NOT NULL
- Crear índices estratégicos

#### 3.4 Seed Data
- Insertar categorías iniciales globales
- Usuario administrador de prueba
- Datos de ejemplo para testing

#### 3.5 Validación
- Todas las tablas visibles en SQL Developer
- Relaciones correctas
- Índices creados
- Inserción de datos funciona

#### 3.6 Evidencia y Commit
- Screenshots: SQL Developer con tablas
- SQL scripts en `/backend/database/schemas/`
- Commit: "feat(database): create oracle database schema"

---

### FASE 4: BACKEND - CONEXIÓN A ORACLE
**Duración estimada:** 2-3 horas

#### 4.1 Configuración de node-oracledb
- Instalar dependencia
- `config/database.js`
- Pool de conexiones
- Manejo de conexiones

#### 4.2 Prueba de Conexión
- Query simple: `SELECT * FROM USUARIO`
- Validar obtención de datos

#### 4.3 Utility Functions
- Función para ejecutar queries parametrizadas
- Manejo de errores de conexión
- Logging de queries (en desarrollo)

#### 4.4 Validación
- Conexión establecida correctamente
- Query retorna datos esperados
- Manejo de errores funciona

#### 4.5 Evidencia y Commit
- Screenshot: Console mostrando conexión exitosa
- Commit: "feat(backend): connect to Oracle Database"

---

### FASE 5: BACKEND - AUTENTICACIÓN (JWT)
**Duración estimada:** 4-5 horas

#### 5.1 Utilidades de Seguridad
- `utils/encryption.js`: hash bcryptjs
- `utils/errors.js`: clases de error personalizadas
- `services/token.service.js`: generación JWT, refresh

#### 5.2 Middleware de Autenticación
- `middleware/auth.middleware.js`
- Verificación de token
- Extracción de datos

#### 5.3 Rutas de Autenticación
- `routes/auth.routes.js`
- `controllers/auth.controller.js`
- `services/auth.service.js`
- Endpoints: POST /registro, POST /login, POST /refresh-token, POST /logout

#### 5.4 Validadores
- `validators/auth.validator.js`
- Esquemas Joi para registro y login

#### 5.5 Pruebas (Postman)
- Registro → nuevo usuario creado
- Login → access token + refresh token
- Refresh token → nuevo access token
- Token expirado → 401 Unauthorized

#### 5.6 Evidencia y Commit
- Screenshots: Postman con cada endpoint
- JWT decodificado (jwt.io)
- Commit: "feat(backend): implement JWT authentication"

---

### FASE 6: BACKEND - AUTORIZACIÓN Y ROLES
**Duración estimada:** 2-3 horas

#### 6.1 Middleware de Autorización
- `middleware/authorization.middleware.js`
- `middleware/verify-ownership.middleware.js`

#### 6.2 Decoradores/Helpers
- Función para proteger rutas por rol
- Función para validar propiedad de recurso

#### 6.3 Pruebas (Postman)
- Usuario accede a su recurso → 200
- Usuario accede a otro recurso → 403
- Admin accede a recursos → 200 (con restricciones)
- Sin token → 401

#### 6.4 Evidencia y Commit
- Screenshots: Postman mostrando 403 en acceso denegado
- Commit: "feat(backend): add authorization and role-based access"

---

### FASE 7: BACKEND - CRUD USUARIOS
**Duración estimada:** 3-4 horas

#### 7.1 Recursos
- `models/usuario.js`: Queries SQL
- `controllers/usuario.controller.js`: Lógica
- `services/usuario.service.js`: Negocio
- `routes/usuario.routes.js`: Endpoints

#### 7.2 Endpoints
- GET /api/v1/usuarios/:id (obtener perfil)
- PUT /api/v1/usuarios/:id (actualizar)
- DELETE /api/v1/usuarios/:id (eliminar)
- POST /api/v1/usuarios/:id/cambiar-password
- GET /api/v1/usuarios (solo ADMIN)

#### 7.3 Validadores
- Email único
- Contraseña nueva válida
- Datos obligatorios

#### 7.4 Pruebas (Postman)
- Obtener perfil propio → datos correctos
- Actualizar perfil → cambios aplicados
- Cambiar contraseña → funciona en siguiente login
- Ver otros usuarios → 403

#### 7.5 Evidencia y Commit
- Screenshots: Postman CRUD usuarios
- Commit: "feat(backend): implement user CRUD"

---

### FASE 8: BACKEND - CRUD CATEGORÍAS
**Duración estimada:** 2-3 horas

#### 8.1 Recursos
- `models/categoria.js`
- `controllers/categoria.controller.js`
- `services/categoria.service.js`
- `routes/categoria.routes.js`

#### 8.2 Endpoints
- GET /api/v1/categorias (propias + globales)
- POST /api/v1/categorias (crear personal)
- PUT /api/v1/categorias/:id
- DELETE /api/v1/categorias/:id
- POST /api/v1/admin/categorias (crear global, ADMIN)

#### 8.3 Validadores
- Nombre único por usuario/tipo
- Tipo: INGRESO o GASTO
- Activo: S/N

#### 8.4 Pruebas (Postman)
- Crear categoría personal
- Listar (incluye globales)
- Actualizar propia
- Intentar actualizar de otro → 403

#### 8.5 Evidencia y Commit
- Commit: "feat(backend): implement category CRUD"

---

### FASE 9: BACKEND - CRUD INGRESOS
**Duración estimada:** 3-4 horas

#### 9.1 Recursos
- `models/ingreso.js`
- `controllers/ingreso.controller.js`
- `services/ingreso.service.js`
- `routes/ingreso.routes.js`

#### 9.2 Endpoints
- GET /api/v1/ingresos (paginado, filtrable)
- GET /api/v1/ingresos/:id
- POST /api/v1/ingresos
- PUT /api/v1/ingresos/:id
- DELETE /api/v1/ingresos/:id
- GET /api/v1/ingresos/estadisticas/total

#### 9.3 Paginación y Filtros
- Parámetros: page, limit, sort, order
- Filtros: fechaInicio, fechaFin, categoria, tipo
- Índices: INGRESO(ID_USUARIO, FECHA_INGRESO)

#### 9.4 Validadores
- Monto > 0
- Categoría debe ser INGRESO
- Fecha válida
- Usuario propietario

#### 9.5 Pruebas (Postman)
- Crear ingreso
- Listar con paginación
- Filtrar por fecha/categoría
- Estadísticas
- Acceso denegado a otros

#### 9.6 Evidencia y Commit
- Screenshots: Postman con paginación y filtros
- Commit: "feat(backend): implement income (ingreso) CRUD"

---

### FASE 10: BACKEND - CRUD GASTOS
**Duración estimada:** 3-4 horas

#### 10.1 Recursos (similar a Ingresos)
- `models/gasto.js`
- `controllers/gasto.controller.js`
- `services/gasto.service.js`
- `routes/gasto.routes.js`

#### 10.2 Endpoints
- GET, POST, PUT, DELETE (similar a ingresos)
- Adicionalmente: GET /api/v1/gastos/presupuesto/alerta

#### 10.3 Lógica Especial: Advertencia de Presupuesto

**Al crear/actualizar gasto:**
```
1. Obtener gasto total del mes
2. Obtener presupuesto del mes
3. Si gasto >= presupuesto * 0.8:
   - Retornar advertencia en respuesta
4. Si gasto >= presupuesto:
   - Retornar ALERTA CRÍTICA
```

#### 10.4 Validadores
- Similar a ingresos
- Categoría debe ser GASTO
- Tipo: ESENCIAL, DISCRECIONAL, INVERSIÓN
- PAGADO: S/N

#### 10.5 Pruebas (Postman)
- Crear gasto dentro presupuesto
- Crear gasto que supera 80% → advertencia
- Crear gasto que supera 100% → alerta crítica
- Verificar que se registra igualmente

#### 10.6 Evidencia y Commit
- Screenshots: Respuesta con advertencia
- Commit: "feat(backend): implement expense (gasto) CRUD"

---

### FASE 11: BACKEND - CRUD PRESUPUESTOS
**Duración estimada:** 2-3 horas

#### 11.1 Recursos
- `models/presupuesto.js`
- `controllers/presupuesto.controller.js`
- `services/presupuesto.service.js`
- `routes/presupuesto.routes.js`

#### 11.2 Endpoints
- GET /api/v1/presupuestos
- GET /api/v1/presupuestos/:id
- POST /api/v1/presupuestos
- PUT /api/v1/presupuestos/:id
- DELETE /api/v1/presupuestos/:id
- GET /api/v1/presupuestos/:id/estado
- GET /api/v1/presupuestos/:id/detalle

#### 11.3 Lógica
- Un presupuesto por usuario/mes/año
- Alerta en porcentaje configurable (20-100)
- Estado actual vs presupuesto calculado

#### 11.4 Validadores
- Monto > 0
- Mes: 1-12
- Año: válido
- Un único por período

#### 11.5 Pruebas (Postman)
- Crear presupuesto
- Obtener estado (vs gastos del mes)
- Actualizar límite
- No permitir duplicados

#### 11.6 Evidencia y Commit
- Commit: "feat(backend): implement budget (presupuesto) CRUD"

---

### FASE 12: BACKEND - REPORTES Y ESTADÍSTICAS
**Duración estimada:** 3-4 horas

#### 12.1 Recursos
- `controllers/reporte.controller.js`
- `services/reporte.service.js`
- `models/queries.js` (consultas complejas)
- `routes/reporte.routes.js`

#### 12.2 Endpoints de Reportes
- GET /api/v1/reportes/resumen-mes
- GET /api/v1/reportes/resumen-año
- GET /api/v1/reportes/gasto-por-categoria
- GET /api/v1/reportes/ingreso-por-categoria
- GET /api/v1/reportes/tendencia
- GET /api/v1/reportes/comparativa

#### 12.3 Consultas SQL Optimizadas
- JOIN con CATEGORIA
- GROUP BY categoría/mes
- Cálculos: SUM, AVG, COUNT
- Evitar N+1 con agregaciones

#### 12.4 Ejemplo: Reporte Gasto por Categoría

```sql
SELECT 
  c.NOMBRE,
  c.COLOR_HEX,
  SUM(g.MONTO) as TOTAL,
  COUNT(*) as CANTIDAD,
  AVG(g.MONTO) as PROMEDIO
FROM GASTO g
INNER JOIN CATEGORIA c ON g.ID_CATEGORIA = c.ID_CATEGORIA
WHERE g.ID_USUARIO = :userId
  AND TRUNC(g.FECHA_GASTO, 'MM') = TRUNC(SYSDATE, 'MM')
GROUP BY c.ID_CATEGORIA, c.NOMBRE, c.COLOR_HEX
ORDER BY TOTAL DESC
```

#### 12.5 Pruebas (Postman)
- Resumen mes actual
- Distribución por categoría
- Tendencias múltiples meses
- Comparativa mes anterior

#### 12.6 Evidencia y Commit
- Screenshots: Reportes en Postman
- Commit: "feat(backend): implement financial reports"

---

### FASE 13: BACKEND - SWAGGER Y DOCUMENTACIÓN
**Duración estimada:** 2-3 horas

#### 13.1 Configuración Swagger
- `swagger.js`: Definición OpenAPI
- Instalar `swagger-jsdoc` y `swagger-ui-express`
- Endpoint: `/api/docs`

#### 13.2 Documentación por Endpoint
- Descripción
- Parámetros
- Esquemas de request/response
- Códigos de error

#### 13.3 Actualizaciones de Documentación
- `/docs/API.md` (endpoints y autenticación)
- `/docs/SEGURIDAD.md` (políticas)
- `/docs/BASE_DE_DATOS.md` (modelo actualizado)

#### 13.4 Validación
- Swagger UI accesible
- Todos los endpoints documentados
- Ejemplos funcionales

#### 13.5 Evidencia y Commit
- Screenshot: Swagger UI
- Commit: "docs(backend): add Swagger/OpenAPI documentation"

---

### FASE 14: BACKEND - OPTIMIZACIÓN
**Duración estimada:** 4-5 horas

#### 14.1 Índices Adicionales
- Verificar índices creados
- Crear índices faltantes
- Documentar justificación

#### 14.2 Caché con Redis (Opcional)
- Configurar Redis (docker-compose.yml)
- `config/redis.js`
- `services/cache.service.js`
- Implementar cache-aside para resúmenes

#### 14.3 Detección y Optimización N+1
- Identificar: listado de gastos sin categoría (problema)
- Solución: JOIN (implementado en fase anterior)
- Comparativa: antes/después

#### 14.4 Compresión y Paginación
- Middleware gzip: `compression()`
- Validar paginación funciona
- Limitar tamaño máximo de response

#### 14.5 Rate Limiting
- `express-rate-limit`
- Endpoints sensibles: 5 req/15 min (login, registro)
- API general: 100 req/min

#### 14.6 Validación y Evidencia
- Mediciones: tiempo query antes/después
- Comparativa: requests con/sin caché
- Screenshots: métricas
- Commit: "perf(backend): add caching, indexes, and optimizations"

---

### FASE 15: BACKEND - PROCESAMIENTO ASINCRÓNICO (Opcional)
**Duración estimada:** 2-3 horas

#### 15.1 Configuración Bull + Redis
- Instalar Bull.js
- `queue/reportQueue.js`
- `queue/workers.js`

#### 15.2 Tarea: Generar Reporte PDF
- POST /api/v1/reportes/generar-pdf → respuesta inmediata {taskId}
- GET /api/v1/reportes/tareas/:taskId → estado
- Worker procesa en background

#### 15.3 Validación
- Task encolada correctamente
- Status: QUEUED → PROCESSING → COMPLETED
- Archivo disponible para descarga

#### 15.4 Evidencia y Commit
- Screenshot: Task en Redis procesándose
- Commit: "feat(backend): add async task processing with Bull"

---

### FASE 16: BACKEND - TESTING COMPLETO
**Duración estimada:** 3-4 horas

#### 16.1 Colección Postman Completa
- Todos los endpoints
- Casos de éxito y error
- Variables y environments

#### 16.2 Pruebas Unitarias (Jest)
- Validadores: Auth, Usuario, Transacciones
- Servicios: Token, Caché
- Cobertura mínima: 70%

#### 16.3 Suite de Integración
- Flujo completo: Registro → CRUD → Logout
- Autenticación: JWT, Refresh, Expiración
- Autorización: Propiedad, Roles
- Paginación y Filtros

#### 16.4 Validación
- Todas las pruebas en verde
- Cobertura documentada
- Casos edge cubiertos

#### 16.5 Evidencia y Commit
- Reporte de cobertura
- Screenshots: Postman tests
- Commit: "test(backend): add comprehensive test suite"

---

### FASE 17: MOBILE - SETUP FLUTTER
**Duración estimada:** 2 horas

#### 17.1 Proyecto Flutter
- `flutter create mobile`
- Estructura de directorios
- pubspec.yaml con dependencias base

#### 17.2 Configuración Base
- `config/constants.dart`
- `config/themes.dart`
- `config/api_config.dart`
- Variables de entorno

#### 17.3 Estructura Providers
- `providers/auth_provider.dart`
- `providers/usuario_provider.dart`
- Estado management con Provider

#### 17.4 Validación
- Proyecto Flutter compila
- Hot reload funciona
- Estructura clara

#### 17.5 Evidencia y Commit
- Commit: "feat(mobile): initialize Flutter project"

---

### FASE 18: MOBILE - SERVICIOS Y MODELOS
**Duración estimada:** 2-3 horas

#### 18.1 Modelos de Datos
- `models/usuario.dart`
- `models/ingreso.dart`
- `models/gasto.dart`
- `models/categoria.dart`
- `models/presupuesto.dart`

#### 18.2 Servicios
- `services/api_service.dart` (cliente HTTP)
- `services/auth_service.dart`
- `services/storage_service.dart` (tokens locales)

#### 18.3 Interceptores HTTP
- Agregar token en headers
- Manejo de errores
- Refresh token automático

#### 18.4 Validación
- Compilación sin errores
- Estructuras serializables JSON

#### 18.5 Evidencia y Commit
- Commit: "feat(mobile): add data models and services"

---

### FASE 19: MOBILE - AUTENTICACIÓN UI
**Duración estimada:** 3-4 horas

#### 19.1 Pantallas
- `screens/auth/login_screen.dart`
- `screens/auth/registro_screen.dart`

#### 19.2 Formularios y Validadores
- Validación en tiempo real
- Campos: correo, contraseña, nombre, etc.
- Mensajes de error claros

#### 19.3 Integración con Backend
- Consumir endpoints `/registro` y `/login`
- Almacenar tokens en secure storage
- Manejo de errores

#### 19.4 Validación
- Login exitoso → Dashboard
- Registro exitoso → Login automático
- Credenciales inválidas → mensaje error
- Validaciones en cliente

#### 19.5 Evidencia y Commit
- Screenshots: Pantallas de login/registro
- Commit: "feat(mobile): implement authentication screens"

---

### FASE 20: MOBILE - DASHBOARD
**Duración estimada:** 2-3 horas

#### 20.1 Dashboard Principal
- `screens/main/dashboard_screen.dart`
- Saldo total (ingresos - gastos)
- Transacciones recientes
- Estado del presupuesto mes actual
- Resumen por categoría

#### 20.2 Widgets
- `widgets/custom_appbar.dart`
- `widgets/transaccion_card.dart`
- `widgets/loading_widget.dart`
- `widgets/error_widget.dart`

#### 20.3 Navigation
- Bottom navigation bar
- Rutas a otras pantallas
- Deep linking (futura)

#### 20.4 Validación
- Dashboard carga correctamente
- Datos refrescados al abrir
- Transiciones suaves

#### 20.5 Evidencia y Commit
- Screenshots: Dashboard
- Commit: "feat(mobile): implement dashboard screen"

---

### FASE 21: MOBILE - CRUD INGRESOS
**Duración estimada:** 2-3 horas

#### 21.1 Pantallas
- `screens/main/ingresos_screen.dart`
- Listado con paginación/filtros
- Detalle de ingreso
- Crear/editar ingreso

#### 21.2 Funcionalidad
- GET /ingresos (listar)
- POST /ingresos (crear)
- PUT /ingresos/:id (actualizar)
- DELETE /ingresos/:id (eliminar)
- Filtros: categoría, fecha

#### 21.3 Validación
- Listado carga correctamente
- Crear/editar/eliminar funcionan
- Cambios reflejados inmediatamente

#### 21.4 Evidencia y Commit
- Screenshots: Ingresos CRUD
- Commit: "feat(mobile): implement income management"

---

### FASE 22: MOBILE - CRUD GASTOS
**Duración estimada:** 2-3 horas

#### 22.1 Pantallas (similar a Ingresos)
- `screens/main/gastos_screen.dart`
- Listado, detalle, crear/editar

#### 22.2 Funcionalidad
- CRUD completo
- Advertencia de presupuesto (si es > 80%)
- Alerta crítica (si es >= 100%)

#### 22.3 Validación
- CRUD funciona correctamente
- Advertencias se muestran
- Datos persisten

#### 22.4 Evidencia y Commit
- Screenshots: Gastos CRUD y advertencias
- Commit: "feat(mobile): implement expense management"

---

### FASE 23: MOBILE - PRESUPUESTOS Y REPORTES
**Duración estimada:** 3-4 horas

#### 23.1 Presupuestos
- `screens/main/presupuestos_screen.dart`
- Crear/editar presupuesto
- Mostrar progreso (barra visual)
- Estado vs gastos

#### 23.2 Reportes
- `screens/main/reportes_screen.dart`
- Resumen mensual
- Gráficos (fl_chart)
- Tendencias
- Comparativas

#### 23.3 Validación
- Presupuestos crean/editan correctamente
- Gráficos se renderizan
- Datos coinciden con backend

#### 23.4 Evidencia y Commit
- Screenshots: Presupuestos y reportes con gráficos
- Commit: "feat(mobile): add budget and reporting features"

---

### FASE 24: MOBILE - PERFIL Y CONFIGURACIÓN
**Duración estimada:** 1-2 horas

#### 24.1 Pantalla de Perfil
- `screens/main/perfil_screen.dart`
- Mostrar datos de usuario
- Editar perfil
- Cambiar contraseña
- Logout

#### 24.2 Funcionalidad
- GET /usuarios/:id
- PUT /usuarios/:id
- POST /usuarios/:id/cambiar-password
- POST /logout

#### 24.3 Validación
- Datos de perfil se cargan
- Ediciones se guardan
- Logout cierra sesión

#### 24.4 Evidencia y Commit
- Commit: "feat(mobile): add user profile and settings"

---

### FASE 25: MOBILE - TESTING Y REFINAMIENTO
**Duración estimada:** 2-3 horas

#### 25.1 Testing Manual
- Flujo completo de usuario
- Casos edge (sin conexión, token expirado)
- Validaciones

#### 25.2 Refinamiento UI/UX
- Animaciones
- Feedback visual
- Accesibilidad

#### 25.3 Validación
- App funciona en emulador Android
- App funciona en emulador iOS (si aplicable)
- No hay crashes

#### 25.4 Evidencia y Commit
- Screenshots: App ejecutándose
- Commit: "test(mobile): complete testing and refinement"

---

### FASE 26: DOCUMENTACIÓN FINAL Y ENTREGA
**Duración estimada:** 2-3 horas

#### 26.1 Actualización de Documentación
- `/docs/GUIA_INSTALACION.md` (completa)
- `/docs/OPTIMIZACION.md` (con resultados reales)
- README.md raíz (actualizado)
- Captura de evidencias

#### 26.2 Organización de Evidencias
- `/docs/EVIDENCIAS/` con todas las screenshots
- Comparativas antes/después (optimizaciones)
- Git log con todos los commits

#### 26.3 Validación Final
- Proyecto compila sin errores
- Todos los endpoints funciona
- Base de datos integra
- Documentación completa

#### 26.4 Commit Final
- "docs: finalize documentation and project"

---

## 16. RIESGOS TÉCNICOS Y MITIGACIÓN

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|-----------|
| Oracle no inicia en Docker | Media | Alto | Usar imagen oficial, volúmenes persistentes, documentar proceso |
| Problemas de conexión node-oracledb | Media | Alto | Usar librería probada, pooling, manejo de reconexión |
| JWT token reutilizado/falsificado | Baja | Crítico | Firma fuerte, verificación rigurosa, no almacenar en localStorage |
| SQL Injection | Baja | Crítico | Siempre usar queries parametrizadas, no concatenar |
| N+1 queries no detectado | Media | Medio | Revisar queries, monitorear base de datos |
| Sesiones simultáneas conflictivas | Baja | Medio | Tokens independientes, validación de propiedad en cada request |
| Caché desincronizado | Baja | Medio | TTL corto, invalidación explícita, logs de caché |
| Flutter no consume API correctamente | Media | Medio | Testing temprano, Postman primero, interceptores |
| Rate limiting demasiado estricto | Baja | Bajo | Configuración flexible, testing bajo carga |
| Cambios en requerimientos a mitad del proyecto | Media | Alto | Documentar decisiones, validar con usuario antes de implementar |

---

## 17. DEPENDENCIAS EXTERNAS REQUERIDAS

### Instalación Previa Obligatoria

**Sistema Operativo (Windows):**
- [ ] Git (https://git-scm.com)
- [ ] Docker Desktop (https://www.docker.com/products/docker-desktop)
- [ ] Node.js 18+ (https://nodejs.org)
- [ ] Flutter SDK (https://flutter.dev/docs/get-started/install/windows)
- [ ] VS Code (https://code.visualstudio.com)
- [ ] Oracle SQL Developer (https://www.oracle.com/database/sqldeveloper)

**Extensiones VS Code Recomendadas:**
- Dart
- Flutter
- REST Client
- SQLTools
- Thunder Client (alternativa Postman)

**Herramientas Opcionales pero Recomendadas:**
- Postman (GUI para testing)
- Redis Desktop Manager (visualizar caché)
- DBeaver (alternativa SQL Developer)

**Verificar Instalación:**
```bash
git --version
docker --version
node --version
npm --version
flutter --version
dart --version
```

---

## 18. CRITERIOS DE FINALIZACIÓN POR FASE

### FASE 1-3 (Infraestructura + BD)
- ✓ Estructura de directorios creada y committed
- ✓ Docker Oracle ejecutándose
- ✓ SQL Developer conectado
- ✓ Todas las tablas creadas
- ✓ Índices creados
- ✓ Seed data insertada

### FASE 4-6 (Backend - Autenticación)
- ✓ Servidor Node.js ejecutándose
- ✓ Conexión a Oracle funciona
- ✓ JWT generado correctamente
- ✓ Tokens se validan
- ✓ Roles funcionan
- ✓ Postman: todos los tests en verde

### FASE 7-12 (Backend - CRUD)
- ✓ Todos los endpoints creados
- ✓ Paginación funciona
- ✓ Filtros funcionan
- ✓ Autorización: usuarios ven solo sus datos
- ✓ Advertencia de presupuesto funciona
- ✓ Reportes retornan datos correctos

### FASE 13-15 (Backend - Documentación y Optimización)
- ✓ Swagger accesible
- ✓ Índices aplicados
- ✓ Caché funciona (si se implementa)
- ✓ N+1 resuelto
- ✓ Rate limiting funciona
- ✓ Comparativa antes/después documentada

### FASE 16 (Backend - Testing)
- ✓ 70%+ cobertura de tests
- ✓ Suite Postman completa
- ✓ Todos los casos de error probados

### FASE 17-24 (Mobile)
- ✓ Proyecto Flutter compila
- ✓ Todas las pantallas implementadas
- ✓ CRUD completo funcionando
- ✓ Integración con API funciona
- ✓ Manejo de errores correcto
- ✓ Tokens se renuevan automáticamente

### FASE 25-26 (Testing Final)
- ✓ App completa funciona sin crashes
- ✓ Documentación actualizada
- ✓ Evidencias guardadas
- ✓ Commits organizados
- ✓ Proyecto listo para entrega

---

## 19. PRIMERA TAREA DE IMPLEMENTACIÓN (SIN EJECUTAR)

### ✅ TAREA 1: ESTRUCTURA INICIAL DEL PROYECTO

**Objetivo:**
Establecer la infraestructura de directorios y configuración básica de Git, lista para comenzar el desarrollo del backend y mobile.

**Alcance:**
- Crear estructura de directorios según propuesta
- Inicializar proyectos Node.js y Flutter (sin dependencias)
- Actualizar .gitignore para backend y mobile
- Crear archivos README en directorios principales
- Crear rama `develop`
- Documentación base

**Archivos a crear:**

```
cashcontrol/
├── mobile/
│   ├── .gitignore
│   ├── pubspec.yaml (vacío, solo estructura)
│   └── README.md
├── backend/
│   ├── src/
│   │   ├── config/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── services/
│   │   ├── middleware/
│   │   ├── validators/
│   │   ├── utils/
│   │   └── app.js (vacío)
│   ├── database/
│   │   └── schemas/
│   ├── .env.example
│   ├── .gitignore
│   ├── package.json (vacío)
│   └── README.md
├── docs/
│   ├── ARQUITECTURA.md (preliminar)
│   ├── BASE_DE_DATOS.md (preliminar)
│   └── GUIA_INSTALACION.md (preliminar)
├── .gitignore (mejorado para backend + mobile)
└── README.md (actualizado)
```

**Pruebas requeridas:**
- Git status limpio (sin archivos no tracked innecesarios)
- Estructura visible en directorios
- Rama `develop` existe

**Evidencia a guardar:**
- Screenshot: Estructura de directorios en Explorer
- Screenshot: `git log --oneline` mostrando commits

**Commit sugerido:**
```
feat: initialize CashControl project structure

- Create mobile/ directory with Flutter structure
- Create backend/ directory with Node.js structure  
- Create docs/ directory with initial documentation
- Add comprehensive .gitignore for both stacks
- Create develop branch
- Add initial README.md files
```

**Por qué esta tarea primero:**
- Es la base para todo lo demás
- No depende de configuración externa
- Permite organizarse antes de programar
- Git queda limpio y estructurado desde el inicio
- Facilita paralelizar trabajo (backend y mobile independientemente)

---

## RESUMEN EJECUTIVO

**Proyecto:** CashControl - Gestión de Finanzas Personales  
**Tecnología:** Flutter + Node.js/Express + Oracle Database  
**Duración estimada:** 26 fases, 60-80 horas de desarrollo  
**Estado actual:** Repositorio vacío, listo para implementación  

**Próximos pasos:**
1. ✅ Usuario revisa y aprueba este plan
2. ⏸️ Espera autorización para comenzar Tarea 1
3. 🔄 Implementar fase por fase (Tarea 1 → Tarea 2 → ...)
4. ✔️ Validar y testear al final de cada fase
5. 📝 Documentar y commitear regularmente

---

**Plan creado:** 2026-08-16  
**Versión:** 1.0  
**Listo para revisión:**✅
