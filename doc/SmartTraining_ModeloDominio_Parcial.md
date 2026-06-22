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
- tarifaEspecial: TarifaEspecial
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
- QUINCENAL
- MENSUAL
- TRIMESTRAL

## TarifaEspecial
- ALCALDIA
- TORTAS_POWER

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

# REGLAS DE NEGOCIO

## Usuario

RN-001
Los roles válidos del sistema son:
- Usuario
- Instructor
- Administrador
- Gerente

RN-002
El estado de un usuario puede ser:
- Activo
- Suspendido
- Moroso

RN-003
Los cambios de estado son realizados manualmente por un Administrador.

RN-004
Los usuarios con membresía vencida pasan automáticamente a estado Moroso.

RN-005
Solo un Administrador puede desbloquear usuarios bloqueados o suspendidos.

RN-006
Solo el Administrador puede visualizar fotos corporales.

RN-007
Solo el Administrador puede modificar medidas físicas registradas.

RN-008
Los instructores tienen acceso gratuito al gimnasio.

---

## Membresía

RN-009
Los planes permitidos son:
- Diario
- Semanal
- Quincenal
- Mensual
- Trimestral

RN-010
Todos los planes tienen acceso a los mismos servicios.

RN-011
No existen planes premium.

RN-012
No existen restricciones horarias por tipo de plan.

RN-013
Una membresía vence exactamente en la fecha calculada desde la compra.

RN-014
Un usuario moroso no puede ingresar al gimnasio.

RN-015
No existe período de gracia para membresías vencidas.

RN-016
La congelación de membresías solo aplica por enfermedad grave u hospitalización.

RN-017
La congelación debe solicitarse antes del vencimiento de la membresía.

RN-018
La fecha de vencimiento debe extenderse automáticamente por los días congelados.

RN-019
Un cambio de plan genera cobro únicamente por la diferencia económica pendiente.

---

## Pago

RN-020
Los métodos de pago válidos son:
- Efectivo
- Transferencia
- Nequi
- Daviplata

RN-021
Se permiten pagos parciales o abonos.

RN-022
El sistema debe impedir pagos duplicados.

RN-023
Los pagos pueden ser editados por Administradores.

RN-024
El registro de pagos genera automáticamente el ingreso correspondiente.

RN-025
El sistema admite promociones y descuentos.

RN-026
El plan Alcaldía tiene tarifa especial de 40.000 COP.

RN-027
El plan Tortas de Power tiene tarifa especial de 45.000 COP.

---

## Rutina

RN-028
Las rutinas son aprobadas por el Instructor.

RN-029
Un usuario puede tener múltiples rutinas activas.

RN-030
Debe mantenerse historial de versiones de rutinas.

RN-031
Las rutinas suelen actualizarse cada tres meses, aunque pueden ajustarse semanal o mensualmente.

RN-032
Un usuario puede tener múltiples objetivos simultáneamente.

RN-033
Los objetivos válidos incluyen:
- Fuerza
- Volumen
- Pérdida de peso
- Resistencia

---

## Entrenamiento

RN-034
Los entrenamientos ya realizados pueden ser modificados.

RN-035
Los usuarios no pueden eliminar ejercicios registrados.

RN-036
El progreso físico se mide mediante:
- Peso
- Porcentaje de grasa
- Porcentaje de músculo

RN-037
La asistencia se registra manualmente.

RN-038
Los usuarios pueden programar descansos.

RN-039
No existe el concepto de falta dentro del negocio.

---

## Máquinas

RN-040
Los estados válidos de una máquina son:
- Disponible
- Mantenimiento
- Fuera de servicio

RN-041
Solo el Administrador puede cambiar el estado de una máquina.

RN-042
Las máquinas no pueden reservarse.

RN-043
Solo el Administrador puede subir videos tutoriales.

---

## Finanzas

RN-044
Las categorías principales de gastos son:
- Empleados
- Mantenimiento
- Servicios

RN-045
Los gastos registrados no pueden modificarse.

RN-046
Solo el Administrador puede eliminar gastos.

RN-047
El gimnasio realiza cierres diarios de caja.

RN-048
El gimnasio maneja caja menor.

RN-049
No se registran devoluciones.

---

## Notificaciones

RN-050
El sistema enviará recordatorios automáticos.

RN-051
Los recordatorios de vencimiento se enviarán tres días antes.

RN-052
Los eventos que generan notificaciones son:
- Vencimiento de membresía
- Pago registrado
- Cambio de rutina
- Inasistencia

RN-053
Deben auditarse:
- Estados financieros
- Usuarios vencidos
- Usuarios registrados por mes
- Progreso físico de usuarios
