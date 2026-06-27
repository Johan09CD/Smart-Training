-- CreateEnum
CREATE TYPE "Rol" AS ENUM ('CLIENTE', 'INSTRUCTOR', 'GERENTE');

-- CreateEnum
CREATE TYPE "EstadoUsuario" AS ENUM ('ACTIVO', 'SUSPENDIDO', 'MOROSO');

-- CreateEnum
CREATE TYPE "TipoPlan" AS ENUM ('DIARIO', 'SEMANAL', 'QUINCENAL', 'MENSUAL', 'TRIMESTRAL');

-- CreateEnum
CREATE TYPE "TarifaEspecial" AS ENUM ('ALCALDIA', 'TORTAS_POWER');

-- CreateEnum
CREATE TYPE "EstadoMembresia" AS ENUM ('ACTIVA', 'INACTIVA', 'CONGELADA');

-- CreateEnum
CREATE TYPE "ConceptoPago" AS ENUM ('MENSUALIDAD', 'INSCRIPCION', 'RENOVACION', 'PLAN_PERSONALIZADO', 'PROMOCION', 'MULTA', 'PRODUCTO', 'OTRO');

-- CreateEnum
CREATE TYPE "MetodoPago" AS ENUM ('EFECTIVO', 'TRANSFERENCIA', 'TARJETA_CREDITO', 'TARJETA_DEBITO', 'NEQUI', 'DAVIPLATA', 'PAYPAL', 'OTRO');

-- CreateEnum
CREATE TYPE "EstadoPago" AS ENUM ('PENDIENTE', 'PAGADO', 'VENCIDO', 'CANCELADO', 'REEMBOLSADO');

-- CreateEnum
CREATE TYPE "ObjetivoPerfil" AS ENUM ('GANAR_MASA_MUSCULAR', 'PERDER_GRASA', 'MEJORAR_CONDICION_FISICA', 'AUMENTAR_FUERZA', 'TONIFICAR', 'RECOMPOSICION_CORPORAL', 'MEJORAR_MOVILIDAD', 'REHABILITACION', 'OTRO');

-- CreateEnum
CREATE TYPE "NivelFitness" AS ENUM ('PRINCIPIANTE', 'INTERMEDIO', 'AVANZADO', 'ATLETA');

-- CreateEnum
CREATE TYPE "Genero" AS ENUM ('MASCULINO', 'FEMENINO', 'OTRO');

-- CreateEnum
CREATE TYPE "GrupoMuscular" AS ENUM ('PECHO', 'ESPALDA', 'HOMBROS', 'BICEPS', 'TRICEPS', 'ANTEBRAZO', 'CUADRICEPS', 'FEMORALES', 'GLUTEOS', 'PANTORRILLAS', 'ABDOMEN', 'CORE', 'CARDIO', 'CUERPO_COMPLETO', 'MOVILIDAD');

-- CreateEnum
CREATE TYPE "DiaSemana" AS ENUM ('LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO', 'DOMINGO');

-- CreateEnum
CREATE TYPE "TipoNotificacion" AS ENUM ('RECORDATORIO_ENTRENAMIENTO', 'NUEVA_RUTINA', 'MEMBRESIA_PROXIMA_VENCER', 'PAGO_VENCIDO');

-- CreateEnum
CREATE TYPE "CanalNotificacion" AS ENUM ('PUSH', 'EMAIL', 'SMS', 'INAPP');

-- CreateEnum
CREATE TYPE "EstadoNotificacion" AS ENUM ('PENDIENTE', 'ENVIADA', 'LEIDA', 'ERROR', 'CANCELADA');

-- CreateEnum
CREATE TYPE "CategoriaIngreso" AS ENUM ('MEMBRESIAS', 'INSCRIPCIONES', 'PLANES_PERSONALIZADOS', 'PRODUCTOS', 'PROMOCIONES', 'OTROS');

-- CreateEnum
CREATE TYPE "CategoriaEgreso" AS ENUM ('ARRIENDO', 'SERVICIOS', 'SALARIOS', 'MANTENIMIENTO', 'INSUMOS', 'MARKETING', 'EQUIPAMIENTO', 'IMPUESTOS', 'OTROS');

-- CreateEnum
CREATE TYPE "EstadoMaquina" AS ENUM ('DISPONIBLE', 'MANTENIMIENTO', 'FUERA_DE_SERVICIO');

-- CreateEnum
CREATE TYPE "ObjetivoEntrenamiento" AS ENUM ('FUERZA', 'VOLUMEN', 'PERDIDA_PESO', 'RESISTENCIA', 'OTRO');

-- CreateTable
CREATE TABLE "usuarios" (
    "id" TEXT NOT NULL,
    "nombre" TEXT NOT NULL,
    "apellido" TEXT NOT NULL,
    "correo" TEXT NOT NULL,
    "telefono" TEXT NOT NULL,
    "fechaNacimiento" TEXT,
    "fotoPerfil" TEXT,
    "passwordHash" TEXT NOT NULL,
    "totpSecret" TEXT,
    "rol" "Rol" NOT NULL DEFAULT 'CLIENTE',
    "estado" "EstadoUsuario" NOT NULL DEFAULT 'ACTIVO',
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "fechaRegistro" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ultimoAcceso" TIMESTAMP(3),

    CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sesiones" (
    "id" TEXT NOT NULL,
    "usuarioId" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "fechaInicio" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "fechaExpiracion" TIMESTAMP(3) NOT NULL,
    "dispositivo" TEXT,
    "activa" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "sesiones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "recuperacion_passwords" (
    "id" TEXT NOT NULL,
    "usuarioId" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "expiracion" TIMESTAMP(3) NOT NULL,
    "utilizado" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "recuperacion_passwords_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "usuarios_correo_key" ON "usuarios"("correo");

-- CreateIndex
CREATE UNIQUE INDEX "sesiones_tokenHash_key" ON "sesiones"("tokenHash");

-- CreateIndex
CREATE UNIQUE INDEX "recuperacion_passwords_tokenHash_key" ON "recuperacion_passwords"("tokenHash");

-- AddForeignKey
ALTER TABLE "sesiones" ADD CONSTRAINT "sesiones_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recuperacion_passwords" ADD CONSTRAINT "recuperacion_passwords_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;
