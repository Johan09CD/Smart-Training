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
## Actividad A0.3 - Hecha sin observasiones todo OK
## Actividad A0.4 - Pendiente cuentas
En los siguientes detalles es mencinado lo que falta y lo ya hecho, lo que está pendiente es debido a esperar la confirmación de cual cuenta será usada para los despliegues de la aplicación. Estas cuentas serán del gym para que ellos queden con disposición del software eso en su propiedad.
### Ya hecho
* .github/workflows/pr-check.yml — exactamente como el doc.
* .github/workflows/deploy-staging.yml — exactamente como el doc.
* apps/web/.gitignore — agregué dev-dist/ para que no se cuele al repo el output de vite-plugin-pwa en modo dev.
### Lo que falta por hacer
* Crear rama de prueba con error TS intencional → check Lint & Build falla — te toca a ti.
* Corregir error → el check pasa — idem.
* Mergear PR → workflow Deploy Staging se dispara — idem.
* Backend responde en URL de Railway tras el deploy — depende del deploy real.
* Frontend carga en URL de Vercel tras el deploy — idem.
### Variables a configurar
1. Cuentas externas conectadas al repo: Vercel (proyecto web) y Railway (servicio smart-training-api). Crear si aún no existen.
2. Secretos en GitHub (Settings → Secrets and variables → Actions):
    * VERCEL_TOKEN, VERCEL_ORG_ID, VERCEL_PROJECT_ID
    * RAILWAY_TOKEN
    * DATABASE_URL (Postgres de Railway)
    * JWT_SECRET, JWT_REFRESH_SECRET (generar con openssl rand -base64 32)
    * REDIS_URL (Upstash)
1. Branch protection en main: requerir el check Lint & Build, bloquear bypass, requerir branch al día.
4. Variables de entorno en Railway → mismas que apps/api/.env.example con valores reales.
5. Variables en Vercel → VITE_API_URL con la URL pública de Railway + /v1.
6. PR de humo: rama → commit con const x: string = 123; en cualquier archivo TS → PR → verificar que Lint & Build falla → corregir → verificar que pasa → merge → ver Deploy Staging correr.