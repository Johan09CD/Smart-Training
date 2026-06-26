## Actividad A0.1
### Desviaciones del documento (autorizadas por ti durante esta actividad)
* turbo.json — renombrado pipeline → tasks (Turbo 2.x cambió la clave).
* tsconfig.base.json — agregadas "module": "ESNext" y "moduleResolution": "Bundler" para que resolveJsonModule sea compatible.
* Nuevos archivos — packages/types/tsconfig.json, packages/validators/tsconfig.json, packages/constants/tsconfig.json (cada uno extiende tsconfig.base.json e incluye src/**/*). El doc no los listaba pero son necesarios para que tsc --noEmit encuentre código a validar. 
### Observación menor
Node es v22.14.0; el doc pide v20.x.x. El engines lo acepta (>=20.0.0) y no causó fallos. Lo dejo así salvo que prefieras instalar v20.
## Actividad A0.2
### Desviaciones del documento (autorizadas en esta actividad)
* Prisma 6 en lugar de 7 — al instalar prisma@^6 y @prisma/client@^6 para mantener compatibilidad con el schema del doc y el PrismaService que importa de @prisma/client. (Prisma 7 cambió la API.)
* DATABASE_URL con password arreglada en apps/api/.env (en vez del postgres del doc) para usar tu Postgres local.
* DB smart_training_dev creada en tu Postgres local — la inicialicé con CREATE DATABASE smart_training_dev vía psql después de que confirmaste credenciales.
### Observación
El proceso terminó con exit 1 en el reporte de tarea de background, pero es porque maté node.exe manualmente con taskkill. El servidor estaba sano antes del kill.