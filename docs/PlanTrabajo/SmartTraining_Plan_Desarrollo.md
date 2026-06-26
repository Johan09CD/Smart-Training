# Smart Training — Plan de Desarrollo por Actividades

**Versión:** 1.0  
**Fecha:** Junio 2026  
**Base:** Modelo de dominio v1.0 · API REST v1.0 · Arquitectura Técnica v1.0  
**Stack:** React + Vite (PWA) · NestJS · PostgreSQL · Prisma · Redis · Cloudinary · FCM · Resend

---

## Convenciones del documento

Cada actividad incluye:
- **Qué se construye** — entregable concreto
- **Reglas de negocio que aplican** — RN relevantes del modelo de dominio
- **Cómo verificar** — criterios de aceptación testeables antes de continuar

> ⚠️ Ninguna actividad debe iniciarse si la anterior no ha pasado su verificación. Este orden respeta las dependencias técnicas y de negocio.

---

## GRUPO 0 — Setup del proyecto
> Duración estimada: 3–5 días  
> Prerequisito: ninguno

---

### A0.1 — Inicializar el monorepo

**Qué se construye:**
Estructura base del repositorio con Turborepo y pnpm workspaces.

```
smart-training/
├── apps/
│   ├── web/        ← vacío por ahora
│   └── api/        ← vacío por ahora
├── packages/
│   ├── types/
│   ├── validators/
│   └── constants/
├── turbo.json
├── pnpm-workspace.yaml
└── package.json
```

**Cómo verificar:**
- [ ] `pnpm install` desde la raíz sin errores
- [ ] `pnpm build` ejecuta el pipeline de Turborepo sin errores
- [ ] Los tres `packages/` son importables desde `apps/api` y `apps/web`

---

### A0.2 — Inicializar el proyecto NestJS (apps/api)

**Qué se construye:**
Proyecto NestJS con módulos vacíos por dominio, Prisma conectado a PostgreSQL local, y variables de entorno documentadas.

Módulos a crear vacíos desde el inicio:
- `AuthModule`
- `UsuariosModule`
- `EntrenamientoModule`
- `MaquinasModule`
- `GimnasioModule`
- `AdminModule`
- `FinanzasModule`
- `NotificacionesModule`
- `ReportesModule`
- `SchedulerModule`

**Cómo verificar:**
- [ ] `pnpm dev` en `apps/api` levanta el servidor sin errores
- [ ] `GET /` responde `200 OK`
- [ ] `npx prisma migrate dev` corre sin errores contra la BD local
- [ ] El archivo `.env.example` documenta todas las variables necesarias

---

### A0.3 — Inicializar el proyecto React PWA (apps/web)

**Qué se construye:**
Proyecto React + Vite con Tailwind, React Router, Axios y el plugin de PWA configurado. Estructura de carpetas por rol lista.

```
apps/web/src/
├── pages/
│   ├── usuario/
│   ├── admin/
│   └── gerente/
├── components/
├── hooks/
├── services/
└── store/
```

**Cómo verificar:**
- [ ] `pnpm dev` levanta la PWA en el navegador sin errores
- [ ] Lighthouse en Chrome reporta la app como "instalable" (PWA check)
- [ ] Las rutas `/usuario`, `/admin`, `/gerente` renderizan sin errores (páginas vacías)
- [ ] Tailwind aplica estilos correctamente en un componente de prueba

---

### A0.4 — Configurar CI/CD

**Qué se construye:**
Pipeline en GitHub Actions que corre lint y build en cada pull request, y despliega automáticamente a Vercel (web) y Railway (api) desde `main`.

**Cómo verificar:**
- [ ] Un PR con código roto falla el pipeline y bloquea el merge
- [ ] Un merge a `main` despliega automáticamente a los entornos de staging
- [ ] Las variables de entorno de producción están configuradas en Vercel y Railway (no en el código)

---

## GRUPO 1 — Autenticación y sesiones
> Duración estimada: 5–7 días  
> Prerequisito: Grupo 0 completo  
> RF cubiertos: RF-01 a RF-10  
> RN que aplican: RN-001, RN-002, RN-008

---

### A1.1 — Schema Prisma: Usuario, Sesion, RecuperacionPassword

**Qué se construye:**
Tablas en PostgreSQL para las entidades de autenticación.

```prisma
model Usuario {
  id               String    @id @default(uuid())
  nombre           String
  apellido         String
  correo           String    @unique
  telefono         String
  fechaNacimiento  String?
  fotoPerfil       String?
  passwordHash     String
  rol              Rol       @default(CLIENTE)
  estado           EstadoUsuario @default(ACTIVO)
  fechaRegistro    DateTime  @default(now())
  ultimoAcceso     DateTime?
  activo           Boolean   @default(true)
  sesiones         Sesion[]
  recuperaciones   RecuperacionPassword[]
}

model Sesion {
  id              String   @id @default(uuid())
  usuarioId       String
  token           String   @unique
  fechaInicio     DateTime @default(now())
  fechaExpiracion DateTime
  dispositivo     String?
  activa          Boolean  @default(true)
  usuario         Usuario  @relation(fields: [usuarioId], references: [id])
}

model RecuperacionPassword {
  id         String   @id @default(uuid())
  usuarioId  String
  token      String   @unique
  expiracion DateTime
  utilizado  Boolean  @default(false)
  usuario    Usuario  @relation(fields: [usuarioId], references: [id])
}
```

**Cómo verificar:**
- [ ] `prisma migrate dev` aplica la migración sin errores
- [ ] Las tres tablas existen en PostgreSQL con las columnas correctas
- [ ] El enum `Rol` contiene `CLIENTE`, `INSTRUCTOR`, `GERENTE` (RN-001)
- [ ] El enum `EstadoUsuario` contiene `ACTIVO`, `SUSPENDIDO`, `MOROSO` (RN-002)

---

### A1.2 — Backend: Endpoints de autenticación

**Qué se construye:**
Implementación completa de `AuthModule` con todos sus endpoints.

| Endpoint | Descripción |
|---|---|
| `POST /auth/registro` | Registro paso 1 — datos básicos |
| `POST /auth/login` | Login para los 3 roles |
| `POST /auth/2fa/verificar` | TOTP para Gerente (RF-04) |
| `POST /auth/refresh` | Renovar access token |
| `POST /auth/recuperar-password` | Envío de email con Resend |
| `POST /auth/reset-password` | Cambio de contraseña con token |
| `POST /auth/logout` | Invalida refresh token en Redis |

**Reglas de negocio a implementar:**
- RN-001: validar que el rol sea uno de los permitidos
- RN-008: si el rol es INSTRUCTOR, no se genera membresía al registrarse

**Cómo verificar:**
- [ ] `POST /auth/registro` crea usuario con `passwordHash` (nunca texto plano) y devuelve tokens
- [ ] `POST /auth/login` con credenciales incorrectas devuelve `401`
- [ ] `POST /auth/login` con rol `GERENTE` devuelve `requiere2FA: true` y sin accessToken
- [ ] `POST /auth/2fa/verificar` con código TOTP válido devuelve tokens completos
- [ ] `POST /auth/recuperar-password` con correo inexistente devuelve `200` (no revela si existe)
- [ ] `POST /auth/logout` invalida el refresh token — el siguiente `POST /auth/refresh` con ese token devuelve `401`
- [ ] Todos los tokens expiran en el tiempo configurado en `.env`

---

### A1.3 — Backend: Guards de roles

**Qué se construye:**
Guards de NestJS que protegen rutas según el rol del JWT.

```typescript
// Uso en controladores:
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Rol.GERENTE)
@Get('/gerente/dashboard')
```

**Cómo verificar:**
- [ ] Un endpoint protegido sin token devuelve `401`
- [ ] Un endpoint de GERENTE con token de CLIENTE devuelve `403`
- [ ] Un endpoint de GERENTE con token de GERENTE devuelve `200`
- [ ] El payload del JWT incluye `usuarioId`, `rol` y `exp`

---

### A1.4 — Frontend: Flujo de login y registro

**Qué se construye:**
Pantallas de login, registro (2 pasos), recuperación de contraseña y verificación 2FA. Manejo de tokens en memoria + refresh automático con Axios interceptor.

**Cómo verificar:**
- [ ] Login exitoso redirige al dashboard según el rol (`/usuario`, `/admin`, `/gerente`)
- [ ] Login fallido muestra mensaje de error sin revelar cuál campo es incorrecto
- [ ] El registro de un CLIENTE crea el perfil físico en el paso 2 (RF-10)
- [ ] Al expirar el access token, el interceptor lo renueva automáticamente con el refresh token sin que el usuario lo note
- [ ] Cerrar sesión borra los tokens del estado y redirige a `/login`
- [ ] En modo PWA, la sesión persiste al cerrar y reabrir el navegador

---

## GRUPO 2 — Perfil de usuario y seguimiento físico
> Duración estimada: 5–7 días  
> Prerequisito: Grupo 1 completo  
> RF cubiertos: RF-08, RF-11 a RF-19  
> RN que aplican: RN-006, RN-007

---

### A2.1 — Schema Prisma: PerfilFisico, RegistroMedidas, SesionFotos

**Qué se construye:**
Tablas para el seguimiento físico del usuario.

**Cómo verificar:**
- [ ] Migración aplica sin errores
- [ ] `PerfilFisico` tiene relación 1:1 con `Usuario`
- [ ] `RegistroMedidas` y `SesionFotos` tienen relación 1:N con `Usuario`
- [ ] Todos los campos de medidas son `Float?` (opcionales — no siempre se miden todos)

---

### A2.2 — Backend: Perfil y contraseña

**Qué se construye:**
Endpoints `GET /usuarios/me`, `PATCH /usuarios/me`, `PATCH /usuarios/me/password`, `PATCH /usuarios/me/perfil-fisico`.

**Cómo verificar:**
- [ ] `GET /usuarios/me` devuelve los datos del usuario autenticado, incluyendo `perfilFisico`
- [ ] `PATCH /usuarios/me/password` con `passwordActual` incorrecto devuelve `400`
- [ ] `PATCH /usuarios/me/perfil-fisico` actualiza objetivo, género y nivel
- [ ] El correo no es modificable desde este endpoint

---

### A2.3 — Backend: Fotos corporales + Cloudinary

**Qué se construye:**
Integración con Cloudinary. Endpoints `POST /usuarios/me/fotos`, `GET /usuarios/me/fotos`, `DELETE /usuarios/me/fotos/:sesionId`.

**Reglas de negocio a implementar:**
- RN-006: el guard verifica que solo ADMIN (INSTRUCTOR) puede ver fotos de otros usuarios — el CLIENTE solo ve las propias

**Cómo verificar:**
- [ ] `POST /usuarios/me/fotos` sube las imágenes a Cloudinary y guarda las URLs en PostgreSQL (nunca el archivo en el servidor)
- [ ] `GET /usuarios/me/fotos` devuelve el timeline ordenado por fecha descendente
- [ ] Un CLIENTE no puede acceder a `GET /usuarios/:id/fotos` de otro usuario — devuelve `403`
- [ ] Un INSTRUCTOR sí puede acceder a `GET /usuarios/:id/fotos` (RN-006)
- [ ] `DELETE` elimina el registro en BD y el archivo en Cloudinary

---

### A2.4 — Backend: Medidas corporales

**Qué se construye:**
Endpoints `POST`, `GET`, `PATCH`, `DELETE` para `RegistroMedidas`.

**Reglas de negocio a implementar:**
- RN-007: solo el ADMIN puede modificar medidas de otros usuarios

**Cómo verificar:**
- [ ] Un CLIENTE puede crear y leer sus propias medidas
- [ ] Un CLIENTE no puede hacer `PATCH` sobre las medidas de otro usuario — `403`
- [ ] Un ADMIN sí puede modificar medidas de cualquier usuario (RN-007)
- [ ] El filtro `?desde=&hasta=` funciona correctamente en el historial

---

### A2.5 — Frontend: Pantallas de perfil y seguimiento físico

**Qué se construye:**
Pantallas de perfil personal, edición de datos, timeline de fotos corporales (con comparación lado a lado) y gráfico de evolución de medidas.

**Cómo verificar:**
- [ ] El usuario puede subir fotos desde la cámara del celular (API `getUserMedia` o `<input type="file" capture>`)
- [ ] El timeline muestra las sesiones fotográficas ordenadas
- [ ] El gráfico de peso muestra la evolución histórica con Recharts
- [ ] El formulario de medidas valida que los valores sean números positivos

---

## GRUPO 3 — Entrenamiento: rutinas, ejercicios y sesiones
> Duración estimada: 8–10 días  
> Prerequisito: Grupo 2 completo  
> RF cubiertos: RF-20 a RF-24, RF-36 a RF-44  
> RN que aplican: RN-028 a RN-039

---

### A3.1 — Schema Prisma: Ejercicio, Rutina, RutinaEjercicio, SesionEntrenamiento, RegistroEjercicio, RegistroAsistencia

**Qué se construye:**
Tablas del dominio de entrenamiento.

**Consideraciones clave:**
- `Rutina` tiene dos FK a `Usuario`: una para el dueño y otra para el instructor que la aprobó (RN-028)
- `RegistroEjercicio` referencia a `SesionEntrenamiento`, no a `Sesion` (corrección del modelo)
- Incluir campo `version` en `Rutina` para el historial de versiones (RN-030)

**Cómo verificar:**
- [ ] Migración aplica sin errores
- [ ] La relación `Rutina → Usuario (dueño)` y `Rutina → Usuario (instructor)` están separadas
- [ ] `RutinaEjercicio` tiene restricción única sobre `(rutinaId, diaSemana, orden)` para evitar colisiones de orden

---

### A3.2 — Backend: Librería de ejercicios

**Qué se construye:**
Endpoints `GET /ejercicios`, `POST /ejercicios`, `PATCH /ejercicios/:id`.

**Cómo verificar:**
- [ ] `GET /ejercicios` permite filtrar por `grupoMuscular` y buscar por nombre
- [ ] Solo un INSTRUCTOR puede crear o editar ejercicios — un CLIENTE recibe `403`
- [ ] Los ejercicios incluyen `videoUrl` e `imagenUrl` desde Cloudinary

---

### A3.3 — Backend: Rutinas

**Qué se construye:**
Endpoints de gestión de rutinas: crear, editar, duplicar, listar por usuario.

**Reglas de negocio a implementar:**
- RN-028: al crear una rutina, el campo `instructor` se toma del usuario autenticado (que debe ser INSTRUCTOR)
- RN-029: un usuario puede tener múltiples rutinas activas — no hay restricción de una sola activa
- RN-030: al editar una rutina, se incrementa `version` y se guarda snapshot del estado anterior

**Cómo verificar:**
- [ ] `POST /usuarios/:id/rutinas` solo lo puede hacer un INSTRUCTOR
- [ ] Crear una rutina incrementa la versión a 1; editarla la lleva a 2, etc.
- [ ] `POST /usuarios/:id/rutinas/:rutinaId/duplicar` crea una copia exacta con `version: 1` y nuevo nombre
- [ ] `GET /usuarios/me/rutina` devuelve la rutina marcada como activa con todos sus ejercicios por día

---

### A3.4 — Backend: Sesiones de entrenamiento

**Qué se construye:**
Endpoints para iniciar, registrar ejercicios y finalizar sesiones.

**Reglas de negocio a implementar:**
- RN-034: los entrenamientos ya realizados pueden modificarse (`PATCH` sobre `RegistroEjercicio`)
- RN-035: los usuarios no pueden eliminar ejercicios registrados — no existe `DELETE` en `RegistroEjercicio`
- Al finalizar la sesión (`completada: true`), calcular y guardar `duracionMinutos` y `volumenTotalKg` automáticamente

**Cómo verificar:**
- [ ] `POST /usuarios/me/sesiones` crea la sesión y devuelve el `id`
- [ ] `POST /usuarios/me/sesiones/:id/ejercicios` agrega ejercicios a la sesión abierta
- [ ] `PATCH` sobre un `RegistroEjercicio` funciona correctamente (RN-034)
- [ ] No existe endpoint `DELETE /usuarios/me/sesiones/:id/ejercicios/:id` (RN-035)
- [ ] Al hacer `PATCH /usuarios/me/sesiones/:id` con `completada: true`, el volumen total se calcula como `Σ(series × reps × peso)` para todos los ejercicios

---

### A3.5 — Backend: Asistencia y calendario

**Qué se construye:**
Endpoints de registro y consulta de asistencia mensual.

**Reglas de negocio a implementar:**
- RN-037: la asistencia se registra manualmente (no hay detección automática)
- RN-038: el tipo `DESCANSO` es válido — el usuario puede registrar días de descanso planificados
- RN-039: no existe el tipo `FALTA` — solo `ENTRENAMIENTO` y `DESCANSO`

**Cómo verificar:**
- [ ] `POST /usuarios/me/asistencia` con `tipo: "FALTA"` devuelve `400` (RN-039)
- [ ] El resumen mensual muestra correctamente `diasEntrenados` y `diasDescanso`
- [ ] No se puede registrar dos veces el mismo día — devuelve `409`

---

### A3.6 — Frontend: Pantallas de entrenamiento

**Qué se construye:**
Calendario mensual de asistencia, vista de rutina activa por día, flujo de registro de sesión en tiempo real, historial de sesiones.

**Cómo verificar:**
- [ ] El calendario muestra días entrenados (verde) y descanso (gris) del mes actual
- [ ] La vista de rutina del día muestra los ejercicios con series, reps y peso sugerido
- [ ] Durante una sesión activa, el usuario puede registrar cada ejercicio y editar los valores
- [ ] Al finalizar la sesión se muestra resumen: duración, volumen total, ejercicios completados
- [ ] El historial de sesiones permite ver el detalle de cada una

---

## GRUPO 4 — Máquinas e información del gimnasio
> Duración estimada: 3–4 días  
> Prerequisito: Grupo 1 completo (independiente de grupos 2 y 3)  
> RF cubiertos: RF-25 a RF-35  
> RN que aplican: RN-040 a RN-043

---

### A4.1 — Schema Prisma: Maquina, Gimnasio

**Qué se construye:**
Tablas para máquinas e información institucional del gimnasio. `Gimnasio` es una tabla de registro único (singleton).

**Cómo verificar:**
- [ ] Migración aplica sin errores
- [ ] El enum `EstadoMaquina` contiene `DISPONIBLE`, `MANTENIMIENTO`, `FUERA_DE_SERVICIO` (RN-040)
- [ ] La tabla `Gimnasio` tiene exactamente un registro en el seed inicial

---

### A4.2 — Backend: Máquinas

**Qué se construye:**
Endpoints CRUD de máquinas y cambio de estado.

**Reglas de negocio a implementar:**
- RN-041: solo el ADMIN puede cambiar el estado de una máquina
- RN-042: no existe endpoint de reserva
- RN-043: solo el ADMIN puede subir videos tutoriales

**Cómo verificar:**
- [ ] Un CLIENTE puede listar y ver el detalle de máquinas, pero no modificarlas (`403`)
- [ ] `PATCH /maquinas/:id/estado` con rol CLIENTE devuelve `403` (RN-041)
- [ ] No existe ningún endpoint `/maquinas/:id/reservar` (RN-042)
- [ ] El video se sube a Cloudinary y se guarda solo la URL

---

### A4.3 — Backend: Información del gimnasio

**Qué se construye:**
Endpoints `GET /gimnasio` y `PATCH /gimnasio`.

**Cómo verificar:**
- [ ] `GET /gimnasio` es accesible para los tres roles
- [ ] `PATCH /gimnasio` solo lo puede hacer un ADMIN — `403` para otros roles
- [ ] El seed carga datos iniciales del gimnasio para que la app no arranque vacía

---

### A4.4 — Frontend: Pantallas de máquinas y gimnasio

**Qué se construye:**
Catálogo de máquinas con filtros, detalle con video tutorial, pantalla de información del gimnasio (misión, visión, horarios, equipo).

**Cómo verificar:**
- [ ] El filtro por `grupoMuscular` y `estado` funciona en el catálogo
- [ ] El video tutorial reproduce correctamente desde la URL de Cloudinary
- [ ] El indicador de estado de cada máquina es visualmente claro (color por estado)
- [ ] La pantalla de gimnasio muestra horarios de apertura por día

---

## GRUPO 5 — Panel del Administrador
> Duración estimada: 4–5 días  
> Prerequisito: Grupos 1, 2 y 3 completos  
> RF cubiertos: RF-45 a RF-52  
> RN que aplican: RN-003, RN-005, RN-006, RN-007

---

### A5.1 — Backend: Dashboard del administrador

**Qué se construye:**
Endpoint `GET /admin/dashboard` con KPIs calculados en tiempo real.

**KPIs a calcular:**
- Usuarios activos totales
- Usuarios que entrenaron hoy
- Nuevos usuarios del mes en curso
- Usuarios inactivos (sin sesión en los últimos 7 días)
- Actividad reciente (últimas sesiones registradas)

**Cómo verificar:**
- [ ] Solo accesible con rol INSTRUCTOR/ADMIN — `403` para CLIENTE y GERENTE
- [ ] Los KPIs se calculan correctamente con datos reales de la BD
- [ ] "Entrenaron hoy" cuenta sesiones con `fecha = today()`

---

### A5.2 — Backend: Gestión de usuarios por el admin

**Qué se construye:**
Endpoints `GET /usuarios`, `GET /usuarios/:id`, `POST /usuarios/:id/notas`, `PATCH /usuarios/:id/notas/:notaId` y cambio de estado de usuario.

**Reglas de negocio a implementar:**
- RN-003: el cambio de estado (ACTIVO → SUSPENDIDO) solo lo hace el ADMIN manualmente
- RN-005: solo el ADMIN puede desbloquear usuarios suspendidos
- RN-004: el cambio automático a MOROSO lo hace el scheduler (se implementa en Grupo 7)

**Cómo verificar:**
- [ ] `GET /usuarios` con filtros `?activo=&rol=&buscar=` devuelve resultados paginados
- [ ] Un ADMIN puede suspender un usuario cambiando su estado
- [ ] Un CLIENTE no puede acceder a `GET /usuarios` — `403`
- [ ] Las notas del instructor se asocian al par `(instructorId, usuarioId)`
- [ ] Editar una nota actualiza `fechaEdicion` automáticamente

---

### A5.3 — Frontend: Panel del administrador

**Qué se construye:**
Dashboard con KPIs, listado de usuarios con indicadores de actividad (semáforo verde/amarillo/rojo), perfil completo de usuario con notas del instructor.

**Cómo verificar:**
- [ ] El indicador de actividad es verde si entrenó en los últimos 3 días, amarillo en 4–7, rojo en más de 7
- [ ] El admin puede escribir y editar notas sobre un usuario
- [ ] El admin puede ver el historial de rutinas y sesiones de cualquier usuario
- [ ] El admin puede cambiar el estado de un usuario desde su perfil

---

## GRUPO 6 — Finanzas: membresías, pagos e ingresos/egresos
> Duración estimada: 8–10 días  
> Prerequisito: Grupos 1 y 5 completos  
> RF cubiertos: RF-53 a RF-80  
> RN que aplican: RN-009 a RN-027, RN-044 a RN-049

---

### A6.1 — Schema Prisma: Plan, Membresia, Pago, Ingreso, Egreso, Descuento, HistorialPrecioPlan

**Qué se construye:**
Tablas del módulo financiero. `HistorialPrecioPlan` registra cada cambio de precio de un plan (RF-76).

**Consideraciones clave:**
- `Plan` tiene campo `tarifaEspecial` nullable para Alcaldía y Tortas de Power (RN-026, RN-027)
- `Pago` tiene campo `esAbono: Boolean` para soportar pagos parciales (RN-021)
- `Egreso` no tiene campo de edición — los gastos son inmutables (RN-045)

**Cómo verificar:**
- [ ] Migración aplica sin errores
- [ ] Los enums de `TipoPlan`, `MetodoPago`, `EstadoPago`, `ConceptoPago` están completos
- [ ] `HistorialPrecioPlan` registra `precioAnterior`, `precioNuevo`, `fecha`, `modificadoPor`
- [ ] El seed carga los planes base: DIARIO, SEMANAL, QUINCENAL, MENSUAL, TRIMESTRAL (RN-009)
- [ ] El seed carga las tarifas especiales con sus precios fijos (RN-026, RN-027)

---

### A6.2 — Backend: Planes y membresías

**Qué se construye:**
Endpoints de planes (`GET`, `POST`, `PATCH`, historial de precios) y membresías (`GET`, `POST /usuarios/:id/membresias`).

**Reglas de negocio a implementar:**
- RN-010 / RN-011 / RN-012: todos los planes dan acceso igualitario — no hay lógica diferenciada por plan
- RN-013: `fechaVencimiento = fechaInicio + plan.duracionDias`
- RN-015: no existe campo de período de gracia
- RN-016 / RN-017 / RN-018: endpoint `POST /membresias/:id/congelar` valida que el estado sea `ACTIVA` y que la solicitud sea antes del vencimiento; al descongelar, extiende `fechaVencimiento`
- RN-019: endpoint `POST /membresias/:id/cambiar-plan` calcula diferencia económica y genera un pago parcial

**Cómo verificar:**
- [ ] Crear membresía calcula `fechaVencimiento` correctamente para cada tipo de plan
- [ ] `PATCH /planes/:id` con nuevo precio registra entrada en `HistorialPrecioPlan`
- [ ] Congelar una membresía ya vencida devuelve `400` (RN-017)
- [ ] Congelar y descongelar extiende la fecha de vencimiento por los días congelados (RN-018)
- [ ] Cambiar plan genera cobro solo por la diferencia (RN-019)

---

### A6.3 — Backend: Pagos

**Qué se construye:**
Endpoints `GET /pagos`, `POST /pagos`, `PATCH /pagos/:id/estado`.

**Reglas de negocio a implementar:**
- RN-020: validar que `metodoPago` sea EFECTIVO, TRANSFERENCIA, NEQUI o DAVIPLATA
- RN-021: campo `esAbono: true` marca pagos parciales
- RN-022: antes de crear un pago, verificar que no exista otro pago para la misma membresía en el mismo día con el mismo monto (anti-duplicado)
- RN-024: al guardar un pago con `estado: PAGADO`, crear automáticamente un registro en `Ingreso` en el mismo transaction de BD

**Cómo verificar:**
- [ ] `POST /pagos` con `metodoPago: "PAYPAL"` devuelve `400` (RN-020)
- [ ] Crear un pago idéntico al del mismo día devuelve `409` (RN-022)
- [ ] Al registrar un pago como PAGADO, existe automáticamente un `Ingreso` correspondiente en la BD (RN-024)
- [ ] Un ADMIN puede editar un pago existente (RN-023) — `PATCH /pagos/:id`
- [ ] Solo el GERENTE puede acceder a los endpoints de pagos

---

### A6.4 — Backend: Ingresos, egresos y balance

**Qué se construye:**
Endpoints `GET /finanzas/ingresos`, `GET /finanzas/egresos`, `POST /finanzas/egresos`, `GET /finanzas/balance`.

**Reglas de negocio a implementar:**
- RN-044: validar que `categoria` de egreso sea una de las permitidas
- RN-045: no existe `PATCH` ni `DELETE` para egresos
- RN-046: si se necesita eliminar un egreso, solo el ADMIN puede hacerlo — endpoint protegido `DELETE /finanzas/egresos/:id` con rol ADMIN
- RN-047: el balance diario se puede consultar con `?periodo=DIARIO`
- RN-049: no existe endpoint de devoluciones

**Cómo verificar:**
- [ ] `PATCH /finanzas/egresos/:id` no existe — devuelve `404` (RN-045)
- [ ] `DELETE /finanzas/egresos/:id` con rol GERENTE devuelve `403` — solo ADMIN (RN-046)
- [ ] `GET /finanzas/balance?periodo=MENSUAL` calcula correctamente `ingresos - egresos = utilidadNeta`
- [ ] El flujo de caja diario muestra entradas y salidas por día del periodo seleccionado

---

### A6.5 — Backend: Descuentos y cobranza

**Qué se construye:**
Endpoints de descuentos (`GET`, `POST`) y cobranza (`GET /cobranza/vencimientos`, `GET /cobranza/morosos`, `POST /cobranza/recordatorio/:usuarioId`).

**Reglas de negocio a implementar:**
- RN-025: al aplicar un descuento, el monto final del pago se calcula con el porcentaje del descuento

**Cómo verificar:**
- [ ] Crear un descuento con `porcentaje: 20` y aplicarlo a un pago de 80.000 resulta en 64.000
- [ ] `GET /cobranza/vencimientos?diasRestantes=3` devuelve usuarios cuya membresía vence en exactamente 1, 2 o 3 días
- [ ] `GET /cobranza/morosos` devuelve usuarios con `estado: MOROSO` y calcula `diasMora` desde `fechaVencimiento`
- [ ] `POST /cobranza/recordatorio/:usuarioId` dispara la notificación por el canal indicado

---

### A6.6 — Backend: Dashboard del gerente

**Qué se construye:**
Endpoint `GET /gerente/dashboard` con KPIs financieros y comparativas de periodo.

**Cómo verificar:**
- [ ] Solo accesible con rol GERENTE (requiere 2FA completado — RN del auth)
- [ ] Los KPIs de ingresos se calculan correctamente para el periodo seleccionado
- [ ] La comparativa con el periodo anterior calcula `variacionPorcentual` correctamente
- [ ] Las alertas (`pagosVencidos`, `membresiasPorVencer`) coinciden con los datos reales

---

### A6.7 — Frontend: Panel del gerente

**Qué se construye:**
Dashboard financiero con gráficos (Recharts), gestión de membresías, registro de pagos, registro de egresos, listado de morosos y cobranza.

**Cómo verificar:**
- [ ] El gráfico de ingresos por semana/mes renderiza correctamente con datos reales
- [ ] El gerente puede registrar un pago manual desde la pantalla de un usuario
- [ ] El listado de morosos muestra días de mora y botón para enviar recordatorio
- [ ] El balance muestra `ingresos`, `egresos` y `utilidad neta` del periodo seleccionado
- [ ] Los filtros de membresías (`estadoPago`, `tipoPlan`, `mesVencimiento`) funcionan correctamente

---

## GRUPO 7 — Notificaciones y tareas automáticas
> Duración estimada: 4–5 días  
> Prerequisito: Grupos 1 y 6 completos  
> RF cubiertos: RF-81 a RF-85  
> RN que aplican: RN-004, RN-050 a RN-053

---

### A7.1 — Schema Prisma: Notificacion, PlantillaMensaje, ConfigNotificacion

**Qué se construye:**
Tablas del módulo de notificaciones. Las plantillas permiten personalizar los mensajes sin tocar código.

**Cómo verificar:**
- [ ] Migración aplica sin errores
- [ ] El seed carga las 4 plantillas base: `RECORDATORIO_ENTRENAMIENTO`, `NUEVA_RUTINA`, `MEMBRESIA_PROXIMA_VENCER`, `PAGO_VENCIDO` (RN-052)
- [ ] `ConfigNotificacion` se crea automáticamente al registrar un usuario nuevo (relación 1:1)

---

### A7.2 — Backend: Integración FCM y Resend

**Qué se construye:**
Servicio `NotificacionesService` que encapsula el envío por canal (PUSH via FCM, EMAIL via Resend). Los controladores solo llaman al servicio — no conocen FCM ni Resend directamente.

**Cómo verificar:**
- [ ] Enviar una notificación PUSH a un dispositivo de prueba llega al celular
- [ ] Enviar un EMAIL a una dirección de prueba llega al correo
- [ ] Si FCM falla, se registra `estado: ERROR` en la tabla `Notificacion` — no rompe el flujo
- [ ] Las plantillas se llenan con datos reales antes de enviar (ej. nombre del usuario, días restantes)

---

### A7.3 — Backend: Scheduler de tareas automáticas

**Qué se construye:**
Módulo `SchedulerModule` con tareas cron usando `@nestjs/schedule`.

| Tarea | Frecuencia | Descripción |
|---|---|---|
| `checkMembresíasVencidas` | Diaria 00:01 | Cambia estado a MOROSO si `fechaVencimiento < hoy` (RN-004) |
| `alertaVencimientoProximo` | Diaria 08:00 | Envía push a usuarios cuya membresía vence en 3 días (RN-051) |
| `recordatorioEntrenamiento` | Según config usuario | Envía push a la hora configurada por el usuario (RF-83) |
| `cierreDiarioCaja` | Diaria 23:55 | Genera snapshot de balance del día (RN-047) |

**Cómo verificar:**
- [ ] Ejecutar `checkMembresíasVencidas` manualmente cambia a MOROSO los usuarios con membresía vencida (RN-004)
- [ ] `alertaVencimientoProximo` envía notificación solo a usuarios con membresía que vence exactamente en 3 días (RN-051)
- [ ] El recordatorio de entrenamiento respeta la hora y días configurados por cada usuario
- [ ] Los cron jobs no se duplican si el servidor se reinicia (usar `@Cron` con `name` único)

---

### A7.4 — Backend: Centro de notificaciones y configuración

**Qué se construye:**
Endpoints `GET /notificaciones/me`, `PATCH /notificaciones/me/:id/leer`, `PATCH /notificaciones/me/leer-todas`, `GET/PATCH /notificaciones/config`, `GET/PATCH /notificaciones/config-automatica`.

**Cómo verificar:**
- [ ] `GET /notificaciones/me?leida=false` devuelve solo las no leídas
- [ ] `PATCH /notificaciones/me/leer-todas` marca todas como leídas y actualiza `fechaLectura`
- [ ] Actualizar `ConfigNotificacion` afecta el comportamiento del scheduler en la siguiente ejecución
- [ ] `GET /notificaciones/config-automatica` solo accesible para GERENTE

---

### A7.5 — Frontend: Centro de notificaciones

**Qué se construye:**
Ícono de campana con badge de no leídas, panel lateral de notificaciones, pantalla de configuración de preferencias.

**Cómo verificar:**
- [ ] El badge muestra el número de notificaciones no leídas y desaparece al marcarlas como leídas
- [ ] Hacer clic en una notificación la marca como leída y navega al contexto relevante (ej. notificación de rutina → pantalla de rutina)
- [ ] La pantalla de configuración permite activar/desactivar push y email, y configurar la hora del recordatorio
- [ ] En Android, el usuario recibe push en segundo plano correctamente

---

## GRUPO 8 — Reportes
> Duración estimada: 3–4 días  
> Prerequisito: Grupo 6 completo  
> RF cubiertos: RF-63 a RF-67  
> RN que aplican: RN-053

---

### A8.1 — Backend: Generación de reportes

**Qué se construye:**
Endpoint `GET /reportes` y `GET /reportes/exportar?formato=PDF|EXCEL` usando PDFKit y ExcelJS.

**Datos que debe incluir el reporte:**
- Total recaudado en el periodo
- Número de pagos: pagados, pendientes, vencidos
- Distribución por plan (porcentaje y monto)
- Listado de transacciones del periodo
- Nuevos usuarios vs cancelaciones

**Reglas de negocio a implementar:**
- RN-053: los reportes deben cubrir estados financieros, usuarios vencidos, usuarios registrados por mes y progreso físico

**Cómo verificar:**
- [ ] `GET /reportes?periodo=MENSUAL&fecha=2026-06` devuelve datos correctos
- [ ] `GET /reportes/exportar?formato=PDF` descarga un PDF legible con los datos del reporte
- [ ] `GET /reportes/exportar?formato=EXCEL` descarga un `.xlsx` con una hoja por sección
- [ ] Solo accesible para GERENTE — `403` para otros roles

---

### A8.2 — Frontend: Pantalla de reportes

**Qué se construye:**
Pantalla del gerente con selector de periodo, vista previa del reporte y botones de descarga PDF/Excel.

**Cómo verificar:**
- [ ] El selector de periodo (MENSUAL, TRIMESTRAL, ANUAL) actualiza los datos al cambiar
- [ ] El botón "Descargar PDF" dispara la descarga del archivo sin navegar fuera de la app
- [ ] Los gráficos de distribución por plan y flujo de caja son legibles en desktop y en móvil

---

## GRUPO 9 — QA final, ajustes y despliegue a producción
> Duración estimada: 5–7 días  
> Prerequisito: Todos los grupos anteriores completos

---

### A9.1 — Pruebas de integración end-to-end

**Qué se prueba:**
Flujos completos de cada rol, de inicio a fin, simulando el uso real del gimnasio.

**Flujos a cubrir:**

**Flujo Cliente:**
1. Registro → completar perfil físico → login
2. Ver rutina del día → iniciar sesión → registrar ejercicios → finalizar sesión
3. Ver calendario de asistencia del mes
4. Subir fotos corporales y registrar medidas
5. Recibir notificación de membresía próxima a vencer

**Flujo Admin/Instructor:**
1. Login → ver dashboard con KPIs
2. Buscar usuario → ver perfil completo → agregar nota
3. Crear ejercicio en librería → asignar rutina a usuario
4. Cambiar estado de una máquina
5. Suspender y rehabilitar un usuario

**Flujo Gerente:**
1. Login con 2FA → ver dashboard financiero
2. Asignar membresía a usuario → registrar pago
3. Registrar egreso del mes
4. Ver balance mensual y comparativa
5. Enviar recordatorio manual a usuario moroso
6. Exportar reporte mensual en PDF

---

### A9.2 — Pruebas de reglas de negocio críticas

**Casos a verificar explícitamente:**

| RN | Caso de prueba |
|---|---|
| RN-004 | Ejecutar el cron manualmente — usuario con membresía vencida pasa a MOROSO |
| RN-015 | Intentar congelar membresía vencida — debe fallar |
| RN-020 | Intentar pago con método no permitido — `400` |
| RN-022 | Registrar pago duplicado el mismo día — `409` |
| RN-024 | Registrar pago → verificar que `Ingreso` se crea automáticamente |
| RN-035 | Intentar eliminar ejercicio de sesión → endpoint no debe existir |
| RN-039 | Registrar asistencia tipo `FALTA` → `400` |
| RN-041 | CLIENTE intenta cambiar estado de máquina → `403` |
| RN-045 | Intentar editar egreso → endpoint no debe existir |

---

### A9.3 — Pruebas de seguridad básicas

**Qué se verifica:**
- [ ] No existe ningún endpoint que devuelva `passwordHash`
- [ ] El token JWT no contiene datos sensibles más allá de `usuarioId` y `rol`
- [ ] Los endpoints de un rol no son accesibles con token de otro rol
- [ ] El rate limiting bloquea más de 10 intentos de login fallidos por IP en 5 minutos
- [ ] Las URLs de Cloudinary de fotos corporales no son predecibles ni públicas sin autenticación

---

### A9.4 — Configuración de producción

**Qué se configura:**
- Variables de entorno en Vercel (web) y Railway (api) — nunca en el código
- Dominio personalizado para la PWA
- SSL activo en ambos servicios
- Backup automático de PostgreSQL en Railway
- Sentry configurado para captura de errores en frontend y backend

**Cómo verificar:**
- [ ] La PWA carga por HTTPS en el dominio de producción
- [ ] Lighthouse en producción da score ≥ 90 en Performance, Accessibility y PWA
- [ ] El backend responde en menos de 500ms en el percentil 95 para endpoints simples
- [ ] Un error intencional en producción aparece en el dashboard de Sentry

---

### A9.5 — Distribución inicial en el gimnasio

**Qué se hace:**
Generación del QR de instalación, instrucciones para el personal y para los usuarios.

**Instrucciones para Android (Chrome):**
1. Abrir el enlace de la app en Chrome
2. Tocar el banner "Añadir a pantalla de inicio" o usar el menú ⋮ → "Instalar app"

**Instrucciones para iOS (Safari, iOS 16.4+):**
1. Abrir el enlace en Safari (no Chrome)
2. Tocar el ícono de compartir → "Añadir a pantalla de inicio"

**Cómo verificar:**
- [ ] La app instalada en Android muestra el ícono correcto y abre sin barra del navegador
- [ ] La app instalada en iOS funciona con notificaciones push activas
- [ ] El personal del gimnasio puede completar los flujos principales sin asistencia técnica

---

## Resumen de tiempos estimados

| Grupo | Módulo | Días estimados |
|---|---|---|
| G0 | Setup del proyecto | 3–5 |
| G1 | Autenticación y sesiones | 5–7 |
| G2 | Perfil y seguimiento físico | 5–7 |
| G3 | Entrenamiento completo | 8–10 |
| G4 | Máquinas y gimnasio | 3–4 |
| G5 | Panel administrador | 4–5 |
| G6 | Finanzas completo | 8–10 |
| G7 | Notificaciones y scheduler | 4–5 |
| G8 | Reportes | 3–4 |
| G9 | QA y despliegue | 5–7 |
| **Total** | | **~48–64 días hábiles** |

> Los grupos G3 y G4 pueden correr en paralelo si hay más de un desarrollador. Lo mismo aplica para G7 y G8 una vez G6 está completo.

---

*Smart Training App · Plan de Desarrollo · Versión 1.0 · Junio 2026*
