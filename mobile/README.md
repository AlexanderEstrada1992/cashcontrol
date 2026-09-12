# CashControl Mobile

## Descripción general

CashControl es una aplicación móvil para la gestión de finanzas personales. La solución actual mantiene un flujo real de:

- Flutter cliente
- API REST en Node.js
- Oracle Database
- SQLite local para soporte offline y sincronización

## Arquitectura real

```text
Flutter App
  ↓
Node.js API REST
  ↓
Oracle Database
```

Además, la app mantiene almacenamiento local con SQLite para sincronización offline y cola de operaciones.

## Endpoint principal y validación

La API real expone los siguientes endpoints:

```text
GET /api/health
GET /api/gastos
POST /api/gastos
```

El endpoint `/api/health` se utiliza para comprobar la disponibilidad de la API y la conexión con Oracle.

## Sistema de diseño

El proyecto usa un sistema de diseño centralizado en `mobile/lib/core/theme/cashcontrol_theme.dart`.

### Tokens primitivos

- Colores base: `primary`, `surface`, `background`, `textPrimary`, `textSecondary`, `success`, `error`, `warning`, `info`, `border`, `muted`
- Tipografías: 14, 16, 20, 24
- Espaciados: 4, 8, 12, 16, 24, 32
- Radios: 8, 12, 16, 24

### Tokens semánticos

Los componentes consumen valores del tema mediante `Theme.of(context).extension<CashControlColors>()`, evitando repetir colores y tamaños dentro de cada widget.

## Componentes reutilizables

Se implementaron los siguientes widgets reutilizables:

- `AppButton`
- `AppTextField`
- `ExpenseCard`
- `AsyncStateView`

Estos componentes fueron diseñados para ser independientes del backend, la navegación y la pantalla concreta donde se usan.

## Accesibilidad

Se incorporaron medidas de accesibilidad para requisitos de Semana 10:

- contraste WCAG AA
- área táctil mínima de 48x48
- `Semantics` en acciones y vistas importantes
- uso de texto, iconos y color para comunicar estados

## Pruebas adaptativas

La pantalla principal usa `LayoutBuilder` para adaptarse a anchos pequeños y grandes, y mantiene un diseño robusto frente a texto ampliado.

## Semana 10

El proyecto queda preparado para la generación del informe técnico de diseño de interfaces y componentes reutilizables, conservando la funcionalidad de sincronización y persistencia local de la Semana 12.

## Ejecución

Desde la carpeta `mobile`:

```bash
flutter pub get
flutter test
flutter run
```
