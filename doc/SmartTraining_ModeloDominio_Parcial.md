# Smart Training - Modelo de Dominio

> Documento de contexto para IA.
> Basado en el diagrama de clases actual.
> Las reglas de negocio se agregarán posteriormente sin modificar la estructura.

---

# ENTIDADES

## Usuario
### Atributos
- nombre: String
- apellido: String
- correo: String
- telefono: String
- fechaNacimiento: String
- fotoPerfil: String
- rol: Rol
- fechaRegistro: DateTime
- ultimoAcceso: DateTime
- activo: Boolean

### Relaciones
- PerfilFisico
- RegistroMedidas
- SesionFotos
- RegistroAsistencia
- Membresia
- Pago
- Rutina
- SesionEntrenamiento
- Notificacion
- ConfigNotificacion
- Sesion
- RecuperacionPassword

### Reglas de negocio
> Pendiente de definición

---

## PerfilFisico
### Atributos
- usuario: Usuario
- objetivo: ObjetivoPerfil
- genero: Genero
- nivelFitness: NivelFitness

### Reglas de negocio
> Pendiente de definición

---

## RegistroMedidas
### Atributos
- usuario: Usuario
- fecha: Date
- pesoKg: Float
- alturaCm: Float
- cinturaCm: Float
- caderaCm: Float
- pechoCm: Float
- bicepsIzqCm: Float
- bicepsDerCm: Float
- musloIzqCm: Float
- musloDerCm: Float

### Reglas de negocio
> Pendiente de definición

---

## SesionFotos
### Atributos
- usuario: Usuario
- fecha: Date
- fotoFrontal: String
- fotoPosterior: String
- fotoLateralIzq: String
- fotoLateralDer: String

### Reglas de negocio
> Pendiente de definición

---

## RegistroAsistencia
### Atributos
- usuario: Usuario
- fecha: Date
- tipo: Enum

---

## NotaInstructor
### Atributos
- instructor: Usuario
- contenido: String
- fechaCreacion: DateTime
- fechaEdicion: DateTime

---

## Plan
### Atributos
- tipo: TipoPlan
- precio: Double
- duracionDias: Int

---

## Membresia
### Atributos
- usuario: Usuario
- plan: Plan
- fechaInicio: Date
- fechaVencimiento: Date
- estado: EstadoMembresia
- renovacionAutomatica: Boolean

---

## Pago
### Atributos
- usuario: Usuario
- membresia: Membresia
- concepto: ConceptoPago
- monto: Float
- metodoPago: MetodoPago
- estado: EstadoPago
- fechaPago: DateTime
- registradoPor: Usuario
- notas: String
- referenciaTransaccion: String

---

## Rutina
### Atributos
- usuario: Usuario
- instructor: Usuario
- nombre: String
- descripcion: String
- objetivo: ObjetivoEntrenamiento
- activa: Boolean
- fechaCreacion: DateTime
- fechaModificacion: DateTime

### Relaciones
- RutinaEjercicio
- SesionEntrenamiento

---

## Ejercicio
### Atributos
- nombre: String
- descripcion: String
- grupoMuscular: GrupoMuscular
- videoUrl: String
- imagenUrl: String
- creadoPor: Usuario

---

## RutinaEjercicio
### Atributos
- rutina: Rutina
- ejercicio: Ejercicio
- diaSemana: DiaSemana
- orden: Int
- seriesSugeridas: Int
- repsSugeridas: Int
- pesoSugerido: Float
- descansoSeg: Int
- notas: String

---

## SesionEntrenamiento
### Atributos
- usuario: Usuario
- rutina: Rutina
- fecha: Date
- horaInicio: DateTime
- horaFin: DateTime
- duracionMinutos: Int
- volumenTotalKg: Float
- completada: Boolean
- notas: String

---

## RegistroEjercicio
### Atributos
- sesion: Sesion
- ejercicioId: UUID
- orden: Int
- seriesRealizadas: Int
- repsRealizadas: Int
- pesoKg: Float
- completado: Boolean
- notas: String

---

## Notificacion
### Atributos
- usuario: Usuario
- tipo: TipoNotificacion
- canal: CanalNotificacion
- mensaje: String
- estado: EstadoNotificacion
- plantillaOrigen: PlantillaMensaje
- fechaEnvio: DateTime
- fechaLectura: DateTime
- creadaEn: DateTime

---

## PlantillaMensaje
### Atributos
- tipo: TipoNotificacion
- tituloTemplate: String
- cuerpoTemplate: String
- activa: Boolean

---

## ConfigNotificacion
### Atributos
- usuario: Usuario
- pushActivo: Boolean
- whatsappActivo: Boolean
- emailActivo: Boolean
- recordatorioEntrenamiento: Boolean
- horaRecordatorio: Time
- diasRecordatorio: String

---

## Sesion
### Atributos
- usuario: Usuario
- token: String
- fechaInicio: DateTime
- fechaExpiracion: DateTime
- dispositivo: String
- activa: Boolean

---

## RecuperacionPassword
### Atributos
- usuario: Usuario
- token: String
- expiracion: DateTime
- utilizado: Boolean

---

## Ingreso
### Atributos
- categoria: CategoriaIngreso
- concepto: ConceptoPago
- descripcion: String
- monto: Double
- fecha: DateTime
- metodoPago: MetodoPago
- registradoPor: Usuario
- comprobante: String
- pagoRelacionado: Pago

---

## Egreso
### Atributos
- registradoPor: Usuario
- categoria: CategoriaEgreso
- descripcion: String
- monto: Float
- fecha: DateTime
- comprobante: String

---

# ENUMERACIONES

## Rol
- CLIENTE
- INSTRUCTOR
- GERENTE

## TipoPlan
- DIARIO
- SEMANAL
- MENSUAL
- ALCALDIA
- FAMILIAR

## EstadoMembresia
- ACTIVA
- INACTIVA
- CONGELADA

## ConceptoPago
- MENSUALIDAD
- INSCRIPCION
- RENOVACION
- PLAN_PERSONALIZADO
- PROMOCION
- MULTA
- PRODUCTO
- OTRO

## MetodoPago
- EFECTIVO
- TRANSFERENCIA
- TARJETA_CREDITO
- TARJETA_DEBITO
- NEQUI
- DAVIPLATA
- PAYPAL
- OTRO

## EstadoPago
- PENDIENTE
- PAGADO
- VENCIDO
- CANCELADO
- REEMBOLSADO

## ObjetivoPerfil
- GANAR_MASA_MUSCULAR
- PERDER_GRASA
- MEJORAR_CONDICION_FISICA
- AUMENTAR_FUERZA
- TONIFICAR
- RECOMPOSICION_CORPORAL
- MEJORAR_MOVILIDAD
- REHABILITACION
- OTRO

## NivelFitness
- PRINCIPIANTE
- INTERMEDIO
- AVANZADO
- ATLETA

## Genero
- MASCULINO
- FEMENINO
- OTRO

## GrupoMuscular
- PECHO
- ESPALDA
- HOMBROS
- BICEPS
- TRICEPS
- ANTEBRAZO
- CUADRICEPS
- FEMORALES
- GLUTEOS
- PANTORRILLAS
- ABDOMEN
- CORE
- CARDIO
- CUERPO_COMPLETO
- MOVILIDAD

## DiaSemana
- LUNES
- MARTES
- MIERCOLES
- JUEVES
- VIERNES
- SABADO
- DOMINGO

## TipoNotificacion
- RECORDATORIO_ENTRENAMIENTO
- NUEVA_RUTINA
- MEMBRESIA_PROXIMA_VENCER
- PAGO_VENCIDO

## CanalNotificacion
- PUSH
- EMAIL
- SMS
- INAPP

## EstadoNotificacion
- PENDIENTE
- ENVIADA
- LEIDA
- ERROR
- CANCELADA

## CategoriaIngreso
- MEMBRESIAS
- INSCRIPCIONES
- PLANES_PERSONALIZADOS
- PRODUCTOS
- PROMOCIONES
- OTROS

## CategoriaEgreso
- ARRIENDO
- SERVICIOS
- SALARIOS
- MANTENIMIENTO
- INSUMOS
- MARKETING
- EQUIPAMIENTO
- IMPUESTOS
- OTROS

---

# SECCION RESERVADA PARA REGLAS DE NEGOCIO

## Usuario
Pendiente

## Membresia
Pendiente

## Pago
Pendiente

## Rutina
Pendiente

## Entrenamiento
Pendiente

## Finanzas
Pendiente

## Notificaciones
Pendiente
