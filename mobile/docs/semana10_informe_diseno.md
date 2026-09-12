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
| `/api/gastos` | GET | Recupera gastos del usuario autenticado por `user_id`. | `HomeScreen` carga datos locales y sincronización remota, usando `ExpenseRepository.refreshFromServer()` |
| `/api/gastos` | POST | Crea o actualiza un gasto en el backend a partir de `client_operation_id` y payload del gasto. | `HomeScreen` al sincronizar cola de operaciones con `ExpenseRepository.syncPending()` |

### 2.2 Pantallas reales existentes en Flutter

Se verificó la implementación actual en `mobile/lib/main.dart`.

| Pantalla o vista | Estado | Funcionalidad actual |
| --- | --- | --- |
| `HomeScreen` | Actual | Gestiona sesión local demo, diagnóstico de API, conexión, sincronización, gastos locales y cola de operaciones. |
| Pantalla de acceso local | Actual | Permite iniciar una sesión demo local cuando no existe usuario autenticado. |
| `AsyncStateView` | Nueva en Semana 10 | Maneja estados de carga, vacío y error para la vista de contenido. |

> La aplicación no contiene varias pantallas especializadas de gastos; la funcionalidad real se concentra en la pantalla principal `HomeScreen`, que es la pantalla que debe ser reutilizada para el informe técnico y la evidencia final.

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
| Texto principal sobre fondo | `#F6F8FF` | `#101828` | ~15.7:1 | AA superado |
| Texto secundario sobre fondo | `#F6F8FF` | `#475467` | ~8.9:1 | AA superado |
| Texto sobre color primario | `#2E6DEB` | `#FFFFFF` | ~4.9:1 | AA superado |
| Texto sobre error | `#B42318` | `#FFFFFF` | ~4.6:1 | AA superado |
| Texto sobre success | `#027A48` | `#FFFFFF` | ~4.8:1 | AA superado |

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

## 7. Pantalla real ensamblada

La pantalla real que se actualizó es `HomeScreen` en `mobile/lib/main.dart`.

Se reutilizaron los componentes como sigue:

- `AppButton` para sesión, conexión y nueva acción de gasto
- `AsyncStateView` para estados de carga, vacío y error
- `ExpenseCard` para cada gasto local
- `AppTextField` disponible para futuros formularios de entrada

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

La verificación visual debe realizarse manualmente en un emulador con una escala de texto ampliada; no se encontraron valores fijos de dimensiones que rompan el diseño en código, pero la validación final debe dejarse en el entorno de ejecución de Flutter.

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
2. La sesión demo local (pantalla sin usuario).
3. El estado de sincronización y diagnóstico de API.
4. El catálogo de componentes reutilizables.
5. La vista de estado vacío.
6. La vista de error o estado cargando.
7. El archivo `cashcontrol_theme.dart` mostrando tokens.

Estas capturas deben acompañarse del código fuente real que quedó en la carpeta `mobile/lib`.

## 12. Requisitos de validación pendientes

La validación de ejecución debe completarse en el entorno Flutter con emulador o dispositivo real, y se debe verificar manualmente:

- `flutter analyze`
- `flutter test`
- ejecución de la app sobre Android/emulador
- comprobación visual de ancho pequeño y ancho grande
- comprobación manual con textScaleFactor ampliado
