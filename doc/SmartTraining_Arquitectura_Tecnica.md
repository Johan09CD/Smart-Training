# Smart Training — Arquitectura Técnica

**Versión:** 1.0  
**Fecha:** Junio 2026  
**Estado:** Aprobado para implementación

---

## Tabla de contenidos

1. [Resumen ejecutivo](#1-resumen-ejecutivo)
2. [Decisiones tecnológicas](#2-decisiones-tecnológicas)
3. [Stack tecnológico](#3-stack-tecnológico)
4. [Arquitectura del sistema](#4-arquitectura-del-sistema)
5. [Estructura del monorepo](#5-estructura-del-monorepo)
6. [Capas de la arquitectura](#6-capas-de-la-arquitectura)
7. [Servicios externos e infraestructura](#7-servicios-externos-e-infraestructura)
8. [Ruta de escalabilidad — de PWA a app móvil](#8-ruta-de-escalabilidad--de-pwa-a-app-móvil)
9. [Costos estimados](#9-costos-estimados)
10. [Decisiones pendientes](#10-decisiones-pendientes)

---

## 1. Resumen ejecutivo

Smart Training es una plataforma de gestión de gimnasio con tres roles diferenciados: **Usuario**, **Administrador/Instructor** y **Gerente**. El sistema centraliza entrenamientos, seguimiento físico, control financiero y comunicación entre roles.

### Enfoque arquitectural

La solución se implementa como una **Progressive Web App (PWA)** en su primera fase, con una arquitectura diseñada deliberadamente para escalar a aplicación móvil nativa (React Native / Expo) sin reescribir la lógica de negocio ni el backend.

La estrategia se resume en un principio clave:

> **El backend no sabe ni le importa quién lo consume.** La PWA de hoy y la app móvil del futuro consumen exactamente la misma API.

### Por qué PWA en la fase inicial

| Criterio | Decisión |
|---|---|
| Costo de distribución | $0 — no requiere Google Play ni App Store |
| Alcance de dispositivos | Funciona en cualquier celular con navegador moderno |
| Panel del gerente | Uso cómodo desde desktop sin app separada |
| Acceso a cámara/galería | Soportado nativamente para fotos corporales |
| Notificaciones push | Android sin restricciones; iOS desde versión 16.4+ |
| Distribución interna | Por QR o enlace directo en el gimnasio |

---

## 2. Decisiones tecnológicas

### Opciones evaluadas

| Opción | Descripción | Decisión |
|---|---|---|
| **A — PWA** | React + Vite, distribución web, sin stores | ✅ **Seleccionada — fase 1** |
| B — React Native / Expo | App móvil multiplataforma | 🔜 Planificada para fase 2 |
| C — Next.js Full-Stack | Web con SSR, todo en un repositorio | Descartada |
| D — Nativa pura (Kotlin + Swift) | Android e iOS por separado | Descartada |

### Justificación de la opción A

- Cero costo de stores durante el arranque del negocio.
- Un solo código para móvil y desktop — el gerente opera desde PC, el usuario desde celular.
- La migración a React Native en fase 2 reutiliza el **100% del backend** y los paquetes compartidos del monorepo.
- Google Play tiene costo único de $25 USD; App Store requiere $99 USD/año — ambos son viables cuando el negocio esté establecido.

---

## 3. Stack tecnológico

### Frontend — PWA (fase 1)

| Tecnología | Versión recomendada | Rol |
|---|---|---|
| React | 18+ | Framework UI principal |
| Vite | 5+ | Bundler y servidor de desarrollo |
| Vite PWA Plugin | latest | Service Worker y manifiesto de instalación |
| React Router | v6 | Navegación y protección de rutas por rol |
| Tailwind CSS | v3 | Estilos responsive — mobile-first |
| React Query (TanStack) | v5 | Caché, sincronización y estados de carga |
| Recharts | latest | Gráficos para dashboards del gerente |
| Axios | latest | Cliente HTTP con interceptores para JWT |
| TypeScript | 5+ | Tipado estático en todo el proyecto |

### Backend

| Tecnología | Versión recomendada | Rol |
|---|---|---|
| Node.js | 20 LTS | Runtime del servidor |
| NestJS | 10+ | Framework con arquitectura modular por dominio |
| Prisma | 5+ | ORM — migraciones y tipado automático de BD |
| PostgreSQL | 16 | Base de datos principal relacional |
| Redis | 7 | Caché de sesiones, rate limiting, colas |
| JWT + Refresh Tokens | — | Autenticación stateless con soporte de roles |
| Passport.js | latest | Estrategias de autenticación (local + JWT) |
| Speakeasy | latest | TOTP para doble factor del gerente (RF-04) |
| Bull / BullMQ | latest | Colas de trabajos para notificaciones y reportes |
| PDFKit / ExcelJS | latest | Generación de reportes exportables (RF-67) |

### App móvil (fase 2 — planificada)

| Tecnología | Rol |
|---|---|
| React Native | Framework de UI nativa multiplataforma |
| Expo (SDK 51+) | Toolchain — simplifica builds y acceso a hardware |
| Expo Router | Navegación basada en archivos (mismo patrón que web) |
| NativeWind | Tailwind adaptado para React Native |
| Expo Notifications | Push notifications nativas en iOS y Android |
| Expo Camera / ImagePicker | Acceso a cámara y galería sin restricciones |

> El backend y los paquetes compartidos (`packages/`) no cambian en la fase 2.

---

## 4. Arquitectura del sistema

```
┌─────────────────────────────────────────────────────────┐
│                     CAPA DE CLIENTES                    │
│  ┌───────────────┐  ┌─────────────────┐  ┌───────────┐  │
│  │  PWA (fase 1) │  │ App móvil       │  │  Panel    │  │
│  │  React + Vite │  │ React Native    │  │  gerente  │  │
│  │  + Vite PWA   │  │ Expo (fase 2)   │  │  (web)    │  │
│  └───────┬───────┘  └────────┬────────┘  └─────┬─────┘  │
└──────────┼──────────────────┼─────────────────┼─────────┘
           │                  │                 │
           └──────────────────┼─────────────────┘
                              │  HTTPS / REST
┌─────────────────────────────▼───────────────────────────┐
│                    API GATEWAY / BFF                     │
│       Auth JWT · Rate Limiting · Routing por rol        │
│              Validación de entrada · CORS               │
└─────────────────────────────┬───────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────┐
│              CAPA DE SERVICIOS — NestJS                 │
│                                                         │
│  ┌──────────┐  ┌───────────────┐  ┌──────────────────┐  │
│  │   Auth   │  │ Entrenamiento │  │    Finanzas      │  │
│  │ JWT·2FA  │  │Rutinas·ejerc. │  │ Pagos·membresías │  │
│  └──────────┘  └───────────────┘  └──────────────────┘  │
│                                                         │
│  ┌──────────┐  ┌───────────────┐  ┌──────────────────┐  │
│  │  Perfil  │  │   Máquinas    │  │   Notificaciones │  │
│  │ Fotos·   │  │Estado·tutori. │  │   FCM · Resend   │  │
│  │ medidas  │  └───────────────┘  └──────────────────┘  │
│  └──────────┘                                           │
│                                                         │
│  ┌──────────┐  ┌───────────────┐                        │
│  │ Reportes │  │   Scheduler   │                        │
│  │PDF·Excel │  │ Cron · alertas│                        │
│  └──────────┘  └───────────────┘                        │
└─────────────────────────────┬───────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────┐
│             CAPA DE DATOS E INFRAESTRUCTURA             │
│                                                         │
│  ┌──────────────┐  ┌────────┐  ┌──────────┐  ┌───────┐  │
│  │  PostgreSQL  │  │ Redis  │  │Cloudinary│  │  FCM  │  │
│  │  BD principal│  │ Caché  │  │Fotos·vid.│  │ Resend│  │
│  │  Prisma ORM  │  │Sesiones│  │          │  │       │  │
│  └──────────────┘  └────────┘  └──────────┘  └───────┘  │
│                                                         │
│  Hosting: Vercel (frontend) · Railway (backend + BD)   │
│           Upstash (Redis) · Cloudinary (media)         │
└─────────────────────────────────────────────────────────┘
```

---

## 5. Estructura del monorepo

El proyecto utiliza una arquitectura **Monorepo con Turborepo** y gestión de paquetes con **pnpm workspaces**. Esta estructura es el eje central de la escalabilidad hacia app móvil.

```
smart-training/
│
├── apps/
│   ├── web/                          # PWA — React + Vite (fase 1)
│   │   ├── public/
│   │   │   └── manifest.json         # Manifiesto PWA
│   │   ├── src/
│   │   │   ├── pages/
│   │   │   │   ├── usuario/          # Vistas del rol Usuario
│   │   │   │   ├── admin/            # Vistas del rol Administrador
│   │   │   │   └── gerente/          # Vistas del rol Gerente
│   │   │   ├── components/           # Componentes reutilizables
│   │   │   ├── hooks/                # Custom hooks (useAuth, useRutina, etc.)
│   │   │   ├── services/             # Llamadas a la API
│   │   │   └── store/                # Estado global (Zustand o Context)
│   │   ├── vite.config.ts
│   │   └── package.json
│   │
│   ├── mobile/                       # App React Native / Expo (fase 2)
│   │   ├── app/                      # Expo Router — rutas basadas en archivos
│   │   │   ├── (usuario)/
│   │   │   ├── (admin)/
│   │   │   └── (gerente)/
│   │   ├── components/
│   │   ├── hooks/                    # Reutiliza hooks de packages/hooks
│   │   └── package.json
│   │
│   └── api/                          # Backend NestJS
│       ├── src/
│       │   ├── auth/                 # Módulo de autenticación (RF-01 a RF-10)
│       │   ├── usuarios/             # Módulo de usuarios y perfil
│       │   ├── entrenamiento/        # Módulo de rutinas y ejercicios
│       │   ├── maquinas/             # Módulo de máquinas del gimnasio
│       │   ├── finanzas/             # Módulo financiero y membresías
│       │   ├── notificaciones/       # Módulo de notificaciones push y email
│       │   ├── reportes/             # Módulo de generación de reportes
│       │   └── scheduler/            # Tareas cron y alertas automáticas
│       ├── prisma/
│       │   └── schema.prisma         # Esquema de la base de datos
│       └── package.json
│
├── packages/                         # ← Código compartido entre apps
│   │
│   ├── types/                        # Tipos TypeScript compartidos
│   │   ├── src/
│   │   │   ├── usuario.types.ts      # User, Perfil, Medidas, etc.
│   │   │   ├── entrenamiento.types.ts# Rutina, Ejercicio, Sesion, etc.
│   │   │   ├── finanzas.types.ts     # Pago, Membresia, Egreso, etc.
│   │   │   └── index.ts
│   │   └── package.json
│   │
│   ├── validators/                   # Validaciones Zod compartidas
│   │   ├── src/
│   │   │   ├── auth.validators.ts    # Schemas de login y registro
│   │   │   ├── usuario.validators.ts
│   │   │   └── finanzas.validators.ts
│   │   └── package.json
│   │
│   ├── constants/                    # Constantes y enums compartidos
│   │   ├── src/
│   │   │   ├── roles.ts              # ROL_USUARIO, ROL_ADMIN, ROL_GERENTE
│   │   │   ├── estados.ts            # Estados de máquinas, pagos, etc.
│   │   │   └── config.ts             # Tiempos de expiración JWT, etc.
│   │   └── package.json
│   │
│   └── ui/                           # Componentes de UI compartidos (fase 2)
│       ├── src/
│       │   └── (componentes agnósticos de plataforma)
│       └── package.json
│
├── turbo.json                        # Configuración de Turborepo
├── pnpm-workspace.yaml               # Definición de workspaces
└── package.json                      # Raíz del monorepo
```

### Por qué esta estructura facilita la migración a móvil

El valor central de `packages/` es que cuando se cree `apps/mobile/`, los tipos, validaciones y constantes ya están definidos y probados. No hay duplicación de código entre la PWA y la app nativa.

```
apps/web/     ─┐
               ├─► packages/types       (User, Rutina, Pago...)
apps/mobile/  ─┤   packages/validators  (Zod schemas)
               └─► packages/constants   (roles, estados, enums)
apps/api/     ──►  (mismos types para request/response)
```

---

## 6. Capas de la arquitectura

### 6.1 Capa de clientes

Todos los clientes (PWA, app móvil, panel desktop) se comunican con el mismo backend vía HTTPS. Cada cliente gestiona su propia navegación y UI adaptada al rol y al dispositivo, pero no contiene lógica de negocio.

**Responsabilidades del cliente:**
- Renderizar la interfaz según el rol autenticado.
- Gestionar el estado local de sesión y caché de datos.
- Enviar solicitudes a la API con el token JWT en el header.
- Manejar la instalación como PWA y las notificaciones push.

### 6.2 API Gateway / BFF

Actúa como punto de entrada único para todos los clientes. En fase 1 está integrado en el servidor NestJS; en una fase futura puede extraerse como servicio independiente.

**Responsabilidades:**
- Validar el token JWT en cada solicitud entrante.
- Verificar que el rol del usuario tiene permisos para el endpoint solicitado.
- Aplicar rate limiting por IP y por usuario.
- Redirigir la solicitud al módulo de servicio correspondiente.
- Normalizar errores y respuestas hacia los clientes.

**Roles y permisos — resumen:**

| Módulo | Usuario | Admin | Gerente |
|---|---|---|---|
| Perfil propio | ✅ Lectura/escritura | ✅ Lectura | ✅ Lectura |
| Rutinas | ✅ Lectura | ✅ Creación/edición | ❌ |
| Máquinas | ✅ Lectura | ✅ Gestión completa | ❌ |
| Usuarios (todos) | ❌ | ✅ Gestión completa | ✅ Lectura |
| Finanzas | ❌ | ❌ | ✅ Gestión completa |
| Notificaciones | ✅ Recibe | ✅ Envía | ✅ Envía |
| Reportes | ❌ | ❌ | ✅ Generación completa |

### 6.3 Capa de servicios

Cada módulo de NestJS corresponde a un dominio del negocio y es independiente. Esta separación permite que en el futuro un módulo de alta carga (p. ej. finanzas) pueda extraerse como microservicio sin afectar al resto.

**Módulos y requerimientos funcionales que cubren:**

| Módulo NestJS | RF cubiertos | Descripción |
|---|---|---|
| `AuthModule` | RF-01 a RF-10 | Login, registro, recuperación de contraseña, doble factor |
| `UsuariosModule` | RF-11 a RF-19, RF-48 a RF-52 | Perfil, medidas, fotos corporales, gestión por admin |
| `EntrenamientoModule` | RF-20 a RF-24, RF-36 a RF-44 | Calendario, rutinas, sesiones, historial |
| `MaquinasModule` | RF-25 a RF-30 | Estado, inventario, videos tutoriales |
| `GimnasioModule` | RF-31 a RF-35 | Info del gimnasio, horarios, equipo |
| `AdminModule` | RF-45 a RF-47 | Dashboard del administrador, KPIs operativos |
| `FinanzasModule` | RF-53 a RF-80 | Dashboard gerente, pagos, egresos, membresías, cobranza |
| `NotificacionesModule` | RF-81 a RF-85 | Push via FCM, email via Resend, centro de notificaciones |
| `ReportesModule` | RF-63 a RF-67 | Generación de PDF y Excel, reportes por periodo |
| `SchedulerModule` | RF-78 a RF-80 | Tareas cron — alertas automáticas de vencimiento |

### 6.4 Capa de datos

**PostgreSQL** es la fuente de verdad del sistema. Todas las entidades relacionales (usuarios, membresías, rutinas, pagos, medidas) residen aquí.

**Redis** actúa como capa auxiliar para:
- Caché de sesiones y tokens de refresh.
- Rate limiting por IP.
- Cola de trabajos para notificaciones y reportes (via BullMQ).
- Almacenamiento temporal de códigos de doble factor (TTL corto).

**Cloudinary** gestiona todos los archivos binarios:
- Fotos corporales del usuario (RF-11 a RF-13).
- Fotos de perfil (RF-08).
- Fotos de máquinas y videos tutoriales (RF-28 a RF-30).

Las URLs de Cloudinary se almacenan en PostgreSQL; los archivos nunca se guardan en el servidor de la aplicación.

---

## 7. Servicios externos e infraestructura

### 7.1 Notificaciones

| Servicio | Tipo | Uso en Smart Training | Costo |
|---|---|---|---|
| **Firebase Cloud Messaging (FCM)** | Push nativa | RF-81, RF-82, RF-83, RF-84 | Gratuito sin límite |
| **Resend** | Email transaccional | RF-02 (recuperación), RF-62 (cobros) | Gratis hasta 3.000/mes |

**Flujo de notificación push:**
```
Scheduler (cron) ──► NotificacionesModule ──► FCM API ──► Dispositivo usuario
Gerente (acción) ──► NotificacionesModule ──► FCM API ──► Dispositivo usuario
```

**Compatibilidad PWA:**
- Android: push en PWA funciona sin restricciones.
- iOS: requiere que el usuario haya instalado la PWA en el home screen (iOS 16.4+).
- En la fase móvil (Expo), push funciona perfectamente en ambas plataformas sin restricciones.

### 7.2 Almacenamiento de medios

| Servicio | Uso | Plan gratuito |
|---|---|---|
| **Cloudinary** | Fotos corporales, fotos de perfil, fotos y videos de máquinas | 25 GB almacenamiento / 25 GB transferencia mensual |

### 7.3 Hosting

| Servicio | Qué aloja | Plan recomendado | Costo estimado |
|---|---|---|---|
| **Vercel** | Frontend PWA (apps/web) | Pro | ~$20 USD/mes |
| **Railway** | Backend NestJS + PostgreSQL | Starter | ~$10–20 USD/mes |
| **Upstash** | Redis serverless | Pay-as-you-go | ~$0–5 USD/mes |
| **Cloudinary** | Imágenes y videos | Gratis | $0/mes |

**Costo total estimado en producción: $30–45 USD/mes**

Comparado con app nativa: $25 USD (Play Store, pago único) + $99 USD/año (App Store) + hosting equivalente.

### 7.4 Servicios de desarrollo y CI/CD

| Servicio | Uso |
|---|---|
| **GitHub** | Repositorio del monorepo |
| **GitHub Actions** | CI/CD — lint, tests y deploy automático a Vercel y Railway |
| **Turborepo** | Caché de builds y ejecución paralela de tareas en el monorepo |

---

## 8. Ruta de escalabilidad — de PWA a app móvil

La arquitectura está diseñada para que la migración a React Native sea incremental y de bajo riesgo.

### Fase 1 — PWA (estado actual)

```
apps/web/  ────────────────────────► API REST (apps/api/)
                                          │
                                      PostgreSQL
                                      Redis
                                      Cloudinary
```

**Entregables de fase 1:** Los 85 requerimientos funcionales implementados como PWA instalable.

### Fase 2 — App móvil en paralelo

```
apps/web/     ─┐
               ├──► API REST (apps/api/) — sin cambios
apps/mobile/  ─┘
```

**Pasos de la migración:**

1. Crear `apps/mobile/` en el monorepo con Expo.
2. Instalar `packages/types`, `packages/validators` y `packages/constants` como dependencias del nuevo app.
3. Configurar Expo Router replicando la estructura de rutas de la PWA.
4. Migrar pantalla por pantalla, comenzando por las más usadas (login, rutina del día, calendario).
5. Reemplazar componentes React DOM por sus equivalentes React Native (`<View>`, `<Text>`, `<FlatList>`).
6. Activar Expo Notifications para push nativa en iOS y Android.
7. Publicar en Google Play ($25 USD, pago único) y App Store ($99 USD/año) cuando esté listo.

**Lo que NO cambia en fase 2:**
- Todo el backend (`apps/api/`).
- La base de datos y migraciones Prisma.
- Los tipos, validadores y constantes (`packages/`).
- Los servicios externos (FCM, Resend, Cloudinary).

**Lo que SÍ cambia en fase 2:**
- Se agrega `apps/mobile/` con componentes nativos.
- La distribución pasa de QR/enlace a Google Play / App Store.
- Las notificaciones push funcionan sin las restricciones de iOS que tiene la PWA.

### Fase 3 — Madurez (opcional)

Si el volumen del gimnasio crece significativamente, los módulos de NestJS pueden extraerse como microservicios independientes sin cambiar la API pública. Esta decisión se toma basada en métricas reales de carga, no por adelantado.

---

## 9. Costos estimados

### Fase 1 — PWA en producción

| Rubro | Servicio | Costo mensual |
|---|---|---|
| Frontend | Vercel Pro | $20 USD |
| Backend + BD | Railway Starter | $15 USD |
| Redis | Upstash | $0–5 USD |
| Medios | Cloudinary | $0 |
| Notificaciones push | FCM | $0 |
| Email transaccional | Resend | $0 |
| **Total fase 1** | | **~$35–40 USD/mes** |

### Fase 2 — Adición de app móvil

| Rubro | Servicio | Costo |
|---|---|---|
| Publicación Android | Google Play Console | $25 USD (único) |
| Publicación iOS | Apple Developer Program | $99 USD/año |
| Builds | Expo EAS Build (free tier) | $0 |
| Infraestructura | Sin cambios | ~$35–40 USD/mes |

---

## 10. Decisiones pendientes

Las siguientes decisiones técnicas se definen en la siguiente etapa del proyecto:

| Decisión | Opciones | Prioridad |
|---|---|---|
| Diagrama de clases y modelo de BD | Definición de entidades, relaciones y cardinalidades | Alta |
| Diseño de la API REST | Contrato de endpoints, versionado, formato de respuestas | Alta |
| Sistema de diseño / UI Kit | Shadcn/ui, Radix, o diseño propio con Tailwind | Media |
| Estrategia de tests | Jest + Testing Library, cobertura mínima por módulo | Media |
| Variables de entorno y secretos | Gestión en desarrollo y producción (Railway Secrets, Vercel Env) | Alta |
| Política de backups de BD | Frecuencia, retención, restore procedure | Media |

---

*Smart Training App · Documento de Arquitectura Técnica · Versión 1.0 · Junio 2026*
