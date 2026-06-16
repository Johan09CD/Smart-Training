# Smart Training — Diseño de la API REST

**Versión:** 1.0  
**Fecha:** Junio 2026  
**Base URL:** `https://api.smarttraining.app/v1`  
**Formato:** JSON en todas las peticiones y respuestas  
**Autenticación:** Bearer Token (JWT) en el header `Authorization`

---

## Tabla de contenidos

1. [Convenciones generales](#1-convenciones-generales)
2. [Autenticación](#2-autenticación)
3. [Usuarios y perfil](#3-usuarios-y-perfil)
4. [Seguimiento físico](#4-seguimiento-físico)
5. [Entrenamiento](#5-entrenamiento)
6. [Máquinas](#6-máquinas)
7. [Gimnasio](#7-gimnasio)
8. [Panel Administrador](#8-panel-administrador)
9. [Finanzas y membresías](#9-finanzas-y-membresías)
10. [Reportes](#10-reportes)
11. [Notificaciones](#11-notificaciones)
12. [Resumen de endpoints](#12-resumen-de-endpoints)

---

## 1. Convenciones generales

### 1.1 Estructura de respuesta estándar

Todas las respuestas siguen el mismo envelope:

```json
// Éxito
{
  "ok": true,
  "data": { ... },
  "meta": { "page": 1, "total": 42 }   // solo en listas paginadas
}

// Error
{
  "ok": false,
  "error": {
    "code": "USUARIO_NO_ENCONTRADO",
    "message": "El usuario con id 123 no existe.",
    "details": []
  }
}
```

### 1.2 Códigos HTTP utilizados

| Código | Cuándo se usa |
|---|---|
| `200 OK` | Lectura o actualización exitosa |
| `201 Created` | Recurso creado exitosamente |
| `204 No Content` | Eliminación exitosa |
| `400 Bad Request` | Error de validación en el body o query params |
| `401 Unauthorized` | Token ausente, inválido o expirado |
| `403 Forbidden` | Token válido pero el rol no tiene permiso |
| `404 Not Found` | Recurso no encontrado |
| `409 Conflict` | Conflicto de unicidad (ej. correo ya registrado) |
| `500 Internal Server Error` | Error inesperado del servidor |

### 1.3 Paginación

Los endpoints que devuelven listas aceptan:

```
GET /recurso?page=1&limit=20
```

La respuesta incluye:
```json
"meta": {
  "page": 1,
  "limit": 20,
  "total": 85,
  "totalPages": 5
}
```

### 1.4 Roles y notación de permisos

A lo largo del documento se indica qué roles pueden acceder a cada endpoint:

| Ícono | Rol |
|---|---|
| 🔵 | CLIENTE (usuario del gimnasio) |
| 🔴 | INSTRUCTOR / ADMIN |
| 🟢 | GERENTE |
| 🌐 | Público (sin autenticación) |

---

## 2. Autenticación

### Endpoints

#### `POST /auth/registro` 🌐
Registro de nuevo usuario (paso 1 del flujo de 2 pasos — RF-07, RF-09, RF-10).

**Body:**
```json
{
  "nombre": "Carlos",
  "apellido": "Ramírez",
  "correo": "carlos@email.com",
  "telefono": "3001234567",
  "password": "miPassword123"
}
```

**Respuesta `201`:**
```json
{
  "ok": true,
  "data": {
    "usuarioId": "uuid",
    "correo": "carlos@email.com",
    "accessToken": "eyJ...",
    "refreshToken": "eyJ..."
  }
}
```

---

#### `POST /auth/login` 🌐
Login estándar para los tres roles (RF-01, RF-03, RF-04, RF-05).

**Body:**
```json
{
  "correo": "carlos@email.com",
  "password": "miPassword123"
}
```

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": {
    "usuarioId": "uuid",
    "rol": "CLIENTE",
    "accessToken": "eyJ...",
    "refreshToken": "eyJ...",
    "requiere2FA": false
  }
}
```

> Si el rol es `GERENTE` y tiene 2FA activo, `requiere2FA` será `true` y el accessToken vendrá vacío hasta completar la verificación.

---

#### `POST /auth/2fa/verificar` 🌐
Verificación del código TOTP para el Gerente (RF-04).

**Body:**
```json
{
  "usuarioId": "uuid",
  "codigo": "123456"
}
```

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ..."
  }
}
```

---

#### `POST /auth/refresh` 🌐
Renovar el access token usando el refresh token.

**Body:**
```json
{
  "refreshToken": "eyJ..."
}
```

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": {
    "accessToken": "eyJ..."
  }
}
```

---

#### `POST /auth/recuperar-password` 🌐
Enviar correo de recuperación de contraseña (RF-02).

**Body:**
```json
{
  "correo": "carlos@email.com"
}
```

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": {
    "message": "Si el correo existe, recibirás un enlace en los próximos minutos."
  }
}
```

---

#### `POST /auth/reset-password` 🌐
Cambiar contraseña con el token recibido por correo (RF-02).

**Body:**
```json
{
  "token": "token-de-recuperacion",
  "nuevaPassword": "nuevaPassword456"
}
```

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": {
    "message": "Contraseña actualizada correctamente."
  }
}
```

---

#### `POST /auth/logout` 🔵🔴🟢
Cierre de sesión — invalida el refresh token (RF-06).

**Respuesta `204`**

---

## 3. Usuarios y perfil

### Endpoints

#### `GET /usuarios/me` 🔵🔴🟢
Obtener el perfil del usuario autenticado (RF-17).

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": {
    "id": "uuid",
    "nombre": "Carlos",
    "apellido": "Ramírez",
    "correo": "carlos@email.com",
    "telefono": "3001234567",
    "fotoPerfil": "https://res.cloudinary.com/...",
    "rol": "CLIENTE",
    "fechaRegistro": "2026-01-15T10:00:00Z",
    "ultimoAcceso": "2026-06-10T08:30:00Z",
    "activo": true,
    "membresiaActiva": {
      "plan": "MENSUAL",
      "fechaVencimiento": "2026-07-15"
    },
    "perfilFisico": {
      "objetivo": "GANAR_MASA_MUSCULAR",
      "genero": "MASCULINO",
      "nivelFitness": "INTERMEDIO"
    }
  }
}
```

---

#### `PATCH /usuarios/me` 🔵🔴🟢
Actualizar datos del perfil propio (RF-18).

**Body (todos los campos opcionales):**
```json
{
  "telefono": "3009876543",
  "fotoPerfil": "base64string o URL de Cloudinary"
}
```

**Respuesta `200`:** Perfil actualizado.

---

#### `PATCH /usuarios/me/password` 🔵🔴🟢
Cambiar contraseña desde el perfil (RF-18).

**Body:**
```json
{
  "passwordActual": "miPassword123",
  "nuevaPassword": "nuevaPassword456"
}
```

**Respuesta `200`**

---

#### `PATCH /usuarios/me/perfil-fisico` 🔵
Actualizar objetivo, género y nivel de fitness (paso 2 del registro — RF-10).

**Body:**
```json
{
  "objetivo": "PERDER_GRASA",
  "genero": "MASCULINO",
  "nivelFitness": "PRINCIPIANTE"
}
```

**Respuesta `200`**

---

#### `GET /usuarios` 🔴🟢
Listado de todos los usuarios del gimnasio (RF-48, RF-49, RF-58).

**Query params:**
```
?page=1&limit=20
&buscar=carlos              // búsqueda por nombre
&activo=true                // filtro por actividad
&rol=CLIENTE
&estadoPago=VENCIDO         // solo gerente
&tipoPlan=MENSUAL           // solo gerente
```

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": [
    {
      "id": "uuid",
      "nombre": "Carlos",
      "apellido": "Ramírez",
      "fotoPerfil": "https://...",
      "ultimoEntrenamiento": "2026-06-08",
      "indicadorActividad": "VERDE",
      "membresia": {
        "plan": "MENSUAL",
        "fechaVencimiento": "2026-07-15",
        "estadoPago": "PAGADO"
      }
    }
  ],
  "meta": { "page": 1, "total": 47, "totalPages": 3 }
}
```

---

#### `GET /usuarios/:id` 🔴🟢
Perfil completo de un usuario específico (RF-50, RF-60).

**Respuesta `200`:** Incluye datos personales, perfil físico, membresía activa e historial de pagos (solo para gerente).

---

#### `POST /usuarios/:id/notas` 🔴
Agregar nota del instructor sobre un usuario (RF-51).

**Body:**
```json
{
  "contenido": "Muestra buena progresión en press de banca. Aumentar peso la próxima semana."
}
```

**Respuesta `201`**

---

#### `PATCH /usuarios/:id/notas/:notaId` 🔴
Editar una nota existente (RF-51).

**Body:**
```json
{
  "contenido": "Texto actualizado de la nota."
}
```

**Respuesta `200`**

---

## 4. Seguimiento físico

### 4.1 Fotos corporales

#### `GET /usuarios/me/fotos` 🔵🔴🟢
Timeline de sesiones fotográficas del usuario autenticado (RF-13).

**Query params:**
```
?page=1&limit=10
```

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": [
    {
      "id": "uuid",
      "fecha": "2026-06-01",
      "fotoFrontal": "https://res.cloudinary.com/...",
      "fotoPosterior": "https://res.cloudinary.com/...",
      "fotoLateralIzq": "https://res.cloudinary.com/...",
      "fotoLateralDer": "https://res.cloudinary.com/..."
    }
  ]
}
```

---

#### `GET /usuarios/:id/fotos` 🔴🟢
Timeline de fotos de un usuario específico (RF-50).

**Respuesta `200`:** Igual al endpoint anterior.

---

#### `POST /usuarios/me/fotos` 🔵
Registrar nueva sesión de fotos corporales (RF-11, RF-12).

**Body (`multipart/form-data`):**
```
fecha: "2026-06-15"
fotoFrontal: [archivo]
fotoPosterior: [archivo]
fotoLateralIzq: [archivo]
fotoLateralDer: [archivo]
```

**Respuesta `201`:** URLs de Cloudinary de las fotos subidas.

---

#### `DELETE /usuarios/me/fotos/:sesionId` 🔵
Eliminar una sesión fotográfica.

**Respuesta `204`**

---

### 4.2 Medidas corporales

#### `GET /usuarios/me/medidas` 🔵🔴🟢
Historial de medidas del usuario autenticado (RF-15).

**Query params:**
```
?desde=2026-01-01&hasta=2026-06-30
```

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": [
    {
      "id": "uuid",
      "fecha": "2026-06-01",
      "pesoKg": 78.5,
      "alturaCm": 175,
      "cinturaCm": 82,
      "caderaCm": 96,
      "pechoCm": 100,
      "bicepsIzqCm": 34,
      "bicepsDerCm": 35,
      "musloIzqCm": 58,
      "musloDerCm": 58
    }
  ]
}
```

---

#### `GET /usuarios/:id/medidas` 🔴🟢
Historial de medidas de un usuario específico (RF-50).

---

#### `POST /usuarios/me/medidas` 🔵
Registrar nuevo set de medidas (RF-14).

**Body:**
```json
{
  "fecha": "2026-06-15",
  "pesoKg": 78.5,
  "alturaCm": 175,
  "cinturaCm": 82,
  "caderaCm": 96,
  "pechoCm": 100,
  "bicepsIzqCm": 34,
  "bicepsDerCm": 35,
  "musloIzqCm": 58,
  "musloDerCm": 58
}
```

**Respuesta `201`**

---

#### `PATCH /usuarios/me/medidas/:id` 🔵
Editar un registro de medidas (RF-16).

**Body:** Campos a actualizar (todos opcionales).

**Respuesta `200`**

---

#### `DELETE /usuarios/me/medidas/:id` 🔵
Eliminar un registro de medidas (RF-16).

**Respuesta `204`**

---

## 5. Entrenamiento

### 5.1 Asistencia y calendario

#### `GET /usuarios/me/asistencia` 🔵🔴
Historial de asistencia del usuario autenticado (RF-20, RF-24).

**Query params:**
```
?mes=2026-06        // año-mes para vista mensual
```

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": {
    "mes": "2026-06",
    "resumen": {
      "diasEntrenados": 14,
      "diasDescanso": 4,
      "diasFalta": 2,
      "diasSinRegistrar": 10
    },
    "dias": [
      { "fecha": "2026-06-01", "tipo": "ENTRENAMIENTO" },
      { "fecha": "2026-06-02", "tipo": "DESCANSO" },
      { "fecha": "2026-06-03", "tipo": "FALTA" }
    ]
  }
}
```

---

#### `GET /usuarios/:id/asistencia` 🔴🟢
Asistencia de un usuario específico (RF-50).

---

#### `POST /usuarios/me/asistencia` 🔵
Registrar asistencia de un día (RF-21).

**Body:**
```json
{
  "fecha": "2026-06-15",
  "tipo": "ENTRENAMIENTO"
}
```

> Valores de `tipo`: `ENTRENAMIENTO` | `DESCANSO`

**Respuesta `201`**

---

### 5.2 Rutinas

#### `GET /usuarios/me/rutina` 🔵
Obtener la rutina activa del usuario autenticado (RF-36).

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": {
    "id": "uuid",
    "nombre": "Rutina Fuerza — Mes 1",
    "objetivo": "AUMENTAR_FUERZA",
    "instructor": { "id": "uuid", "nombre": "Pedro", "apellido": "López" },
    "ejercicios": [
      {
        "id": "uuid",
        "diaSemana": "LUNES",
        "orden": 1,
        "ejercicio": {
          "nombre": "Press de Banca",
          "grupoMuscular": "PECHO",
          "videoUrl": "https://res.cloudinary.com/..."
        },
        "seriesSugeridas": 4,
        "repsSugeridas": 8,
        "pesoSugerido": 60,
        "descansoSeg": 90,
        "notas": "Bajar controlado en 3 segundos."
      }
    ]
  }
}
```

---

#### `GET /usuarios/:id/rutinas` 🔴
Todas las rutinas de un usuario específico (RF-52).

**Respuesta `200`:** Lista de rutinas con indicador de cuál está activa.

---

#### `POST /usuarios/:id/rutinas` 🔴
Crear y asignar una rutina a un usuario (RF-40, RF-52).

**Body:**
```json
{
  "nombre": "Rutina Volumen — Mes 2",
  "descripcion": "Enfoque en volumen muscular con series altas.",
  "objetivo": "VOLUMEN",
  "ejercicios": [
    {
      "ejercicioId": "uuid",
      "diaSemana": "LUNES",
      "orden": 1,
      "seriesSugeridas": 5,
      "repsSugeridas": 10,
      "pesoSugerido": 55,
      "descansoSeg": 60,
      "notas": ""
    }
  ]
}
```

**Respuesta `201`**

---

#### `PATCH /usuarios/:id/rutinas/:rutinaId` 🔴
Editar una rutina existente (RF-40).

**Body:** Campos a actualizar.

**Respuesta `200`**

---

#### `POST /usuarios/:id/rutinas/:rutinaId/duplicar` 🔴
Duplicar una rutina y asignarla al usuario indicado (RF-42).

**Body:**
```json
{
  "nuevoNombre": "Rutina Fuerza — Copia"
}
```

**Respuesta `201`:** Nueva rutina creada.

---

### 5.3 Librería de ejercicios

#### `GET /ejercicios` 🔵🔴
Listado de todos los ejercicios disponibles (RF-41).

**Query params:**
```
?buscar=sentadilla
&grupoMuscular=CUADRICEPS
&page=1&limit=30
```

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": [
    {
      "id": "uuid",
      "nombre": "Sentadilla con barra",
      "descripcion": "Ejercicio compuesto para tren inferior.",
      "grupoMuscular": "CUADRICEPS",
      "videoUrl": "https://...",
      "imagenUrl": "https://..."
    }
  ]
}
```

---

#### `POST /ejercicios` 🔴
Crear un nuevo ejercicio en la librería (RF-41).

**Body:**
```json
{
  "nombre": "Sentadilla con barra",
  "descripcion": "Ejercicio compuesto para tren inferior.",
  "grupoMuscular": "CUADRICEPS",
  "videoUrl": "https://res.cloudinary.com/...",
  "imagenUrl": "https://res.cloudinary.com/..."
}
```

**Respuesta `201`**

---

#### `PATCH /ejercicios/:id` 🔴
Editar un ejercicio de la librería.

**Respuesta `200`**

---

### 5.4 Sesiones de entrenamiento

#### `GET /usuarios/me/sesiones` 🔵🔴
Historial de sesiones de entrenamiento del usuario autenticado (RF-43).

**Query params:**
```
?desde=2026-05-01&hasta=2026-06-30
&page=1&limit=20
```

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": [
    {
      "id": "uuid",
      "fecha": "2026-06-10",
      "duracionMinutos": 62,
      "volumenTotalKg": 3840,
      "completada": true,
      "ejerciciosRealizados": 6
    }
  ]
}
```

---

#### `GET /usuarios/me/sesiones/:sesionId` 🔵🔴
Detalle completo de una sesión (RF-43).

**Respuesta `200`:** Incluye cada `RegistroEjercicio` con series, reps y peso real.

---

#### `POST /usuarios/me/sesiones` 🔵
Iniciar una nueva sesión de entrenamiento (RF-37, RF-38, RF-39).

**Body:**
```json
{
  "rutinaId": "uuid",
  "fecha": "2026-06-15",
  "horaInicio": "2026-06-15T07:00:00Z"
}
```

**Respuesta `201`:** Sesión creada con `id`.

---

#### `PATCH /usuarios/me/sesiones/:sesionId` 🔵
Finalizar o actualizar una sesión en curso (RF-44).

**Body:**
```json
{
  "horaFin": "2026-06-15T08:05:00Z",
  "completada": true,
  "notas": "Buena sesión, subí 5kg en press."
}
```

**Respuesta `200`:** Incluye resumen: duración, volumen total, ejercicios completados.

---

#### `POST /usuarios/me/sesiones/:sesionId/ejercicios` 🔵
Registrar un ejercicio dentro de una sesión (RF-37, RF-39).

**Body:**
```json
{
  "ejercicioId": "uuid",
  "orden": 1,
  "seriesRealizadas": 4,
  "repsRealizadas": 8,
  "pesoKg": 65,
  "completado": true,
  "notas": ""
}
```

**Respuesta `201`**

---

#### `PATCH /usuarios/me/sesiones/:sesionId/ejercicios/:registroId` 🔵
Editar un ejercicio ya registrado en la sesión.

**Respuesta `200`**

---

## 6. Máquinas

#### `GET /maquinas` 🔵🔴
Listado de todas las máquinas del gimnasio (RF-25, RF-27).

**Query params:**
```
?buscar=banca
&grupoMuscular=PECHO
&estado=DISPONIBLE
```

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": [
    {
      "id": "uuid",
      "nombre": "Press de Banca Plano",
      "grupoMuscular": "PECHO",
      "estado": "DISPONIBLE",
      "fotoUrl": "https://res.cloudinary.com/..."
    }
  ]
}
```

---

#### `GET /maquinas/:id` 🔵🔴
Detalle completo de una máquina (RF-28).

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": {
    "id": "uuid",
    "nombre": "Press de Banca Plano",
    "descripcion": "Máquina para ejercicios de empuje horizontal.",
    "grupoMuscular": "PECHO",
    "estado": "DISPONIBLE",
    "instrucciones": "Ajustar el asiento a la altura de los hombros...",
    "fotoUrl": "https://...",
    "videoUrl": "https://..."
  }
}
```

---

#### `POST /maquinas` 🔴
Agregar una nueva máquina (RF-30).

**Body (`multipart/form-data`):**
```
nombre: "Press de Banca Plano"
descripcion: "..."
grupoMuscular: "PECHO"
instrucciones: "..."
foto: [archivo]
video: [archivo]
```

**Respuesta `201`**

---

#### `PATCH /maquinas/:id` 🔴
Editar información de una máquina (RF-29).

**Body (todos opcionales):**
```json
{
  "nombre": "Press Banca Plano",
  "estado": "EN_MANTENIMIENTO",
  "descripcion": "..."
}
```

**Respuesta `200`**

---

#### `PATCH /maquinas/:id/estado` 🔴
Cambiar únicamente el estado de una máquina (RF-26, RF-29).

**Body:**
```json
{
  "estado": "OCUPADA"
}
```

> Valores: `DISPONIBLE` | `OCUPADA` | `EN_MANTENIMIENTO`

**Respuesta `200`**

---

## 7. Gimnasio

#### `GET /gimnasio` 🔵🔴🟢
Información general del gimnasio (RF-31, RF-32, RF-33, RF-34, RF-35).

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": {
    "nombre": "Smart Training",
    "logoUrl": "https://...",
    "fotoUrl": "https://...",
    "mision": "...",
    "vision": "...",
    "historia": "...",
    "telefono": "3001234567",
    "whatsapp": "3001234567",
    "horarios": [
      { "dia": "LUNES", "apertura": "05:00", "cierre": "22:00" },
      { "dia": "SABADO", "apertura": "07:00", "cierre": "14:00" }
    ],
    "equipo": [
      {
        "nombre": "Pedro López",
        "especialidad": "Fuerza y acondicionamiento",
        "fotoUrl": "https://..."
      }
    ]
  }
}
```

---

#### `PATCH /gimnasio` 🔴
Actualizar información del gimnasio.

**Body:** Cualquier campo del objeto anterior.

**Respuesta `200`**

---

## 8. Panel Administrador

#### `GET /admin/dashboard` 🔴
KPIs operativos del dashboard del administrador (RF-45, RF-46, RF-47).

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": {
    "kpis": {
      "usuariosActivos": 87,
      "entrenarónHoy": 23,
      "nuevosDelMes": 5,
      "usuariosInactivos": 12
    },
    "actividadReciente": [
      {
        "usuarioId": "uuid",
        "nombre": "Carlos Ramírez",
        "fotoPerfil": "https://...",
        "horaEntrenamiento": "2026-06-15T07:32:00Z",
        "resumenSesion": "6 ejercicios · 3.840 kg volumen"
      }
    ]
  }
}
```

---

## 9. Finanzas y membresías

### 9.1 Dashboard del gerente

#### `GET /gerente/dashboard` 🟢
KPIs financieros principales (RF-53, RF-54, RF-55, RF-56, RF-57).

**Query params:**
```
?periodo=MENSUAL&fecha=2026-06
```

> Valores de `periodo`: `DIARIO` | `SEMANAL` | `MENSUAL` | `TRIMESTRAL` | `SEMESTRAL` | `ANUAL`

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": {
    "periodo": "MENSUAL",
    "kpis": {
      "ingresos": 4850000,
      "miembrosActivos": 87,
      "nuevasInscripciones": 5,
      "cancelaciones": 2,
      "tasaRetencion": 97.7
    },
    "comparativa": {
      "ingresosPeriodoAnterior": 4200000,
      "variacionPorcentual": 15.5,
      "variacionAbsoluta": 650000
    },
    "alertas": {
      "pagosVencidos": 8,
      "membresiasPorVencer": 5,
      "usuariosConDeuda": 8
    },
    "graficoIngresos": [
      { "etiqueta": "Semana 1", "valor": 1200000 },
      { "etiqueta": "Semana 2", "valor": 1350000 }
    ]
  }
}
```

---

### 9.2 Planes y membresías

#### `GET /planes` 🟢
Listado de todos los planes disponibles (RF-74).

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": [
    {
      "id": "uuid",
      "tipo": "MENSUAL",
      "precio": 80000,
      "duracionDias": 30,
      "beneficios": "Acceso completo + clases grupales",
      "usuariosActivos": 52
    }
  ]
}
```

---

#### `POST /planes` 🟢
Crear un nuevo plan (RF-75).

**Body:**
```json
{
  "tipo": "FAMILIAR",
  "precio": 150000,
  "duracionDias": 30,
  "beneficios": "Hasta 3 integrantes del hogar."
}
```

**Respuesta `201`**

---

#### `PATCH /planes/:id` 🟢
Editar precio o beneficios de un plan (RF-75, RF-76).

**Body:**
```json
{
  "precio": 90000,
  "beneficios": "Acceso completo + clases grupales + evaluación mensual"
}
```

> El historial de cambio de precio se registra automáticamente (RF-76).

**Respuesta `200`**

---

#### `GET /planes/:id/historial-precios` 🟢
Historial de cambios de precio de un plan (RF-76).

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": [
    {
      "fecha": "2026-06-01T10:00:00Z",
      "precioAnterior": 75000,
      "precioNuevo": 80000,
      "modificadoPor": "Admin Gerente"
    }
  ]
}
```

---

#### `GET /membresías` 🟢
Listado de membresías con filtros (RF-58, RF-59).

**Query params:**
```
?estadoPago=VENCIDO
&tipoPlan=MENSUAL
&mesVencimiento=2026-07
&nivelActividad=INACTIVO
&page=1&limit=20
```

**Respuesta `200`:** Lista de membresías con datos del usuario asociado.

---

#### `GET /membresías/:id` 🟢
Detalle de una membresía específica.

**Respuesta `200`**

---

#### `POST /usuarios/:id/membresias` 🟢
Asignar una nueva membresía a un usuario.

**Body:**
```json
{
  "planId": "uuid",
  "fechaInicio": "2026-06-15",
  "renovacionAutomatica": false
}
```

**Respuesta `201`**

---

### 9.3 Pagos

#### `GET /pagos` 🟢
Listado de todos los pagos (RF-66).

**Query params:**
```
?desde=2026-06-01&hasta=2026-06-30
&estado=PAGADO
&metodoPago=NEQUI
&usuarioId=uuid
&page=1&limit=20
```

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": [
    {
      "id": "uuid",
      "usuario": { "nombre": "Carlos", "apellido": "Ramírez" },
      "concepto": "MENSUALIDAD",
      "monto": 80000,
      "metodoPago": "NEQUI",
      "estado": "PAGADO",
      "fechaPago": "2026-06-01T09:30:00Z",
      "registradoPor": "Admin Gerente"
    }
  ],
  "meta": { "page": 1, "total": 92 }
}
```

---

#### `POST /pagos` 🟢
Registrar un pago manualmente (RF-61, RF-68).

**Body:**
```json
{
  "usuarioId": "uuid",
  "membresiaId": "uuid",
  "concepto": "MENSUALIDAD",
  "monto": 80000,
  "metodoPago": "EFECTIVO",
  "fechaPago": "2026-06-15T10:00:00Z",
  "notas": "Pago en efectivo recibido en recepción.",
  "referenciaTransaccion": ""
}
```

**Respuesta `201`**

---

#### `PATCH /pagos/:id/estado` 🟢
Marcar un pago como recibido o cambiar su estado (RF-61).

**Body:**
```json
{
  "estado": "PAGADO"
}
```

**Respuesta `200`**

---

### 9.4 Ingresos y egresos

#### `GET /finanzas/ingresos` 🟢
Listado de ingresos del periodo (RF-68, RF-70).

**Query params:**
```
?desde=2026-06-01&hasta=2026-06-30
&categoria=MEMBRESIAS
```

**Respuesta `200`:** Lista de ingresos con totales.

---

#### `GET /finanzas/egresos` 🟢
Listado de egresos del periodo (RF-69, RF-70).

**Query params:**
```
?desde=2026-06-01&hasta=2026-06-30
&categoria=SALARIOS
```

**Respuesta `200`:** Lista de egresos con totales.

---

#### `POST /finanzas/egresos` 🟢
Registrar un gasto del gimnasio (RF-69).

**Body:**
```json
{
  "categoria": "SERVICIOS",
  "descripcion": "Factura de electricidad — Junio 2026",
  "monto": 450000,
  "fecha": "2026-06-10T00:00:00Z",
  "comprobante": "https://res.cloudinary.com/..."
}
```

**Respuesta `201`**

---

#### `GET /finanzas/balance` 🟢
Balance general del periodo seleccionado (RF-70, RF-71, RF-72, RF-73).

**Query params:**
```
?periodo=MENSUAL&fecha=2026-06
```

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": {
    "periodo": "2026-06",
    "ingresosTotales": 4850000,
    "egresosTotales": 1200000,
    "utilidadNeta": 3650000,
    "proyeccionMes": 5100000,
    "flujoCaja": [
      { "fecha": "2026-06-01", "entradas": 320000, "salidas": 0 },
      { "fecha": "2026-06-02", "entradas": 160000, "salidas": 450000 }
    ],
    "historialAnual": [
      { "mes": "2026-01", "ingresos": 4100000, "egresos": 1100000, "utilidad": 3000000, "variacion": null },
      { "mes": "2026-02", "ingresos": 4300000, "egresos": 1050000, "utilidad": 3250000, "variacion": 8.3 }
    ]
  }
}
```

---

### 9.5 Descuentos y cobranza

#### `GET /descuentos` 🟢
Listado de descuentos y promociones activos (RF-77).

**Respuesta `200`**

---

#### `POST /descuentos` 🟢
Crear un descuento o promoción (RF-77).

**Body:**
```json
{
  "codigo": "JULIO20",
  "porcentaje": 20,
  "fechaInicio": "2026-07-01",
  "fechaFin": "2026-07-31",
  "limiteUsos": 50
}
```

**Respuesta `201`**

---

#### `GET /cobranza/vencimientos` 🟢
Usuarios con membresía próxima a vencer (RF-78).

**Query params:**
```
?diasRestantes=7    // 3, 5 o 7
```

**Respuesta `200`:** Lista de usuarios con fecha de vencimiento y botón de recordatorio.

---

#### `GET /cobranza/morosos` 🟢
Usuarios con pago vencido (RF-79).

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": [
    {
      "usuarioId": "uuid",
      "nombre": "Carlos Ramírez",
      "diasMora": 12,
      "montoAdeudado": 80000
    }
  ]
}
```

---

#### `POST /cobranza/recordatorio/:usuarioId` 🟢
Enviar notificación de cobro manual a un usuario (RF-62, RF-79).

**Body:**
```json
{
  "canal": "PUSH",
  "mensaje": "Tienes un pago pendiente. Comunícate con recepción."
}
```

**Respuesta `200`**

---

## 10. Reportes

#### `GET /reportes` 🟢
Generar un reporte para el periodo seleccionado (RF-63, RF-64, RF-65, RF-66).

**Query params:**
```
?periodo=MENSUAL&fecha=2026-06
```

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": {
    "periodo": "MENSUAL",
    "fechaGeneracion": "2026-06-15T12:00:00Z",
    "resumen": {
      "totalRecaudado": 4850000,
      "numeroPagos": 87,
      "pagosPendientes": 8,
      "pagosVencidos": 3
    },
    "distribucionPorPlan": [
      { "plan": "MENSUAL", "porcentaje": 62, "monto": 3007000 },
      { "plan": "FAMILIAR", "porcentaje": 23, "monto": 1115500 }
    ],
    "transacciones": [
      {
        "fecha": "2026-06-01",
        "usuario": "Carlos Ramírez",
        "concepto": "MENSUALIDAD",
        "monto": 80000,
        "metodoPago": "NEQUI",
        "estado": "PAGADO"
      }
    ]
  }
}
```

---

#### `GET /reportes/exportar` 🟢
Exportar un reporte en PDF o Excel (RF-67).

**Query params:**
```
?periodo=MENSUAL&fecha=2026-06&formato=PDF
```

> Valores de `formato`: `PDF` | `EXCEL`

**Respuesta `200`:** Archivo binario con el header `Content-Disposition: attachment`.

---

## 11. Notificaciones

#### `GET /notificaciones/me` 🔵🔴🟢
Centro de notificaciones del usuario autenticado (RF-85).

**Query params:**
```
?page=1&limit=20&leida=false
```

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": [
    {
      "id": "uuid",
      "tipo": "MEMBRESIA_PROXIMA_VENCER",
      "mensaje": "Tu membresía vence en 3 días. Renuévala para seguir entrenando.",
      "canal": "PUSH",
      "estado": "ENVIADA",
      "fechaEnvio": "2026-06-12T08:00:00Z",
      "fechaLectura": null
    }
  ]
}
```

---

#### `PATCH /notificaciones/me/:id/leer` 🔵🔴🟢
Marcar una notificación como leída (RF-85).

**Respuesta `200`**

---

#### `PATCH /notificaciones/me/leer-todas` 🔵🔴🟢
Marcar todas las notificaciones como leídas.

**Respuesta `200`**

---

#### `GET /notificaciones/config` 🔵
Obtener la configuración de notificaciones del usuario (RF-83).

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": {
    "pushActivo": true,
    "emailActivo": true,
    "recordatorioEntrenamiento": true,
    "horaRecordatorio": "07:00",
    "diasRecordatorio": "LUNES,MARTES,MIERCOLES,JUEVES,VIERNES"
  }
}
```

---

#### `PATCH /notificaciones/config` 🔵
Actualizar preferencias de notificación (RF-83).

**Body:**
```json
{
  "recordatorioEntrenamiento": true,
  "horaRecordatorio": "06:30",
  "diasRecordatorio": "LUNES,MIERCOLES,VIERNES,SABADO"
}
```

**Respuesta `200`**

---

#### `GET /notificaciones/config-automatica` 🟢
Obtener la configuración global de alertas automáticas (RF-80).

**Respuesta `200`:**
```json
{
  "ok": true,
  "data": {
    "diasAntesMembresiaVence": 5,
    "enviarAlVencer": true,
    "enviarAviso3Dias": true,
    "enviarAviso7Dias": false
  }
}
```

---

#### `PATCH /notificaciones/config-automatica` 🟢
Configurar alertas automáticas del sistema (RF-80).

**Body:**
```json
{
  "diasAntesMembresiaVence": 7
}
```

**Respuesta `200`**

---

## 12. Resumen de endpoints

| Método | Endpoint | Rol | RF |
|---|---|---|---|
| POST | `/auth/registro` | 🌐 | RF-07 a RF-09 |
| POST | `/auth/login` | 🌐 | RF-01, RF-03–05 |
| POST | `/auth/2fa/verificar` | 🌐 | RF-04 |
| POST | `/auth/refresh` | 🌐 | RF-06 |
| POST | `/auth/recuperar-password` | 🌐 | RF-02 |
| POST | `/auth/reset-password` | 🌐 | RF-02 |
| POST | `/auth/logout` | 🔵🔴🟢 | RF-06 |
| GET | `/usuarios/me` | 🔵🔴🟢 | RF-17 |
| PATCH | `/usuarios/me` | 🔵🔴🟢 | RF-18 |
| PATCH | `/usuarios/me/password` | 🔵🔴🟢 | RF-18 |
| PATCH | `/usuarios/me/perfil-fisico` | 🔵 | RF-10 |
| GET | `/usuarios` | 🔴🟢 | RF-48, RF-58 |
| GET | `/usuarios/:id` | 🔴🟢 | RF-50, RF-60 |
| POST | `/usuarios/:id/notas` | 🔴 | RF-51 |
| PATCH | `/usuarios/:id/notas/:notaId` | 🔴 | RF-51 |
| GET | `/usuarios/me/fotos` | 🔵🔴🟢 | RF-13 |
| GET | `/usuarios/:id/fotos` | 🔴🟢 | RF-50 |
| POST | `/usuarios/me/fotos` | 🔵 | RF-11, RF-12 |
| DELETE | `/usuarios/me/fotos/:sesionId` | 🔵 | RF-12 |
| GET | `/usuarios/me/medidas` | 🔵🔴🟢 | RF-15 |
| GET | `/usuarios/:id/medidas` | 🔴🟢 | RF-50 |
| POST | `/usuarios/me/medidas` | 🔵 | RF-14 |
| PATCH | `/usuarios/me/medidas/:id` | 🔵 | RF-16 |
| DELETE | `/usuarios/me/medidas/:id` | 🔵 | RF-16 |
| GET | `/usuarios/me/asistencia` | 🔵🔴 | RF-20, RF-24 |
| GET | `/usuarios/:id/asistencia` | 🔴🟢 | RF-50 |
| POST | `/usuarios/me/asistencia` | 🔵 | RF-21 |
| GET | `/usuarios/me/rutina` | 🔵 | RF-36 |
| GET | `/usuarios/:id/rutinas` | 🔴 | RF-52 |
| POST | `/usuarios/:id/rutinas` | 🔴 | RF-40, RF-52 |
| PATCH | `/usuarios/:id/rutinas/:rutinaId` | 🔴 | RF-40 |
| POST | `/usuarios/:id/rutinas/:rutinaId/duplicar` | 🔴 | RF-42 |
| GET | `/ejercicios` | 🔵🔴 | RF-41 |
| POST | `/ejercicios` | 🔴 | RF-41 |
| PATCH | `/ejercicios/:id` | 🔴 | RF-41 |
| GET | `/usuarios/me/sesiones` | 🔵🔴 | RF-43 |
| GET | `/usuarios/me/sesiones/:sesionId` | 🔵🔴 | RF-43 |
| POST | `/usuarios/me/sesiones` | 🔵 | RF-37 |
| PATCH | `/usuarios/me/sesiones/:sesionId` | 🔵 | RF-44 |
| POST | `/usuarios/me/sesiones/:sesionId/ejercicios` | 🔵 | RF-37, RF-39 |
| PATCH | `/usuarios/me/sesiones/:sesionId/ejercicios/:id` | 🔵 | RF-37 |
| GET | `/maquinas` | 🔵🔴 | RF-25, RF-27 |
| GET | `/maquinas/:id` | 🔵🔴 | RF-28 |
| POST | `/maquinas` | 🔴 | RF-30 |
| PATCH | `/maquinas/:id` | 🔴 | RF-29 |
| PATCH | `/maquinas/:id/estado` | 🔴 | RF-26, RF-29 |
| GET | `/gimnasio` | 🔵🔴🟢 | RF-31 a RF-35 |
| PATCH | `/gimnasio` | 🔴 | RF-31 a RF-35 |
| GET | `/admin/dashboard` | 🔴 | RF-45, RF-46 |
| GET | `/gerente/dashboard` | 🟢 | RF-53 a RF-57 |
| GET | `/planes` | 🟢 | RF-74 |
| POST | `/planes` | 🟢 | RF-75 |
| PATCH | `/planes/:id` | 🟢 | RF-75, RF-76 |
| GET | `/planes/:id/historial-precios` | 🟢 | RF-76 |
| GET | `/membresías` | 🟢 | RF-58, RF-59 |
| POST | `/usuarios/:id/membresias` | 🟢 | RF-58 |
| GET | `/pagos` | 🟢 | RF-66 |
| POST | `/pagos` | 🟢 | RF-61, RF-68 |
| PATCH | `/pagos/:id/estado` | 🟢 | RF-61 |
| GET | `/finanzas/ingresos` | 🟢 | RF-68 |
| GET | `/finanzas/egresos` | 🟢 | RF-69 |
| POST | `/finanzas/egresos` | 🟢 | RF-69 |
| GET | `/finanzas/balance` | 🟢 | RF-70 a RF-73 |
| GET | `/descuentos` | 🟢 | RF-77 |
| POST | `/descuentos` | 🟢 | RF-77 |
| GET | `/cobranza/vencimientos` | 🟢 | RF-78 |
| GET | `/cobranza/morosos` | 🟢 | RF-79 |
| POST | `/cobranza/recordatorio/:usuarioId` | 🟢 | RF-62, RF-79 |
| GET | `/reportes` | 🟢 | RF-63, RF-64 |
| GET | `/reportes/exportar` | 🟢 | RF-67 |
| GET | `/notificaciones/me` | 🔵🔴🟢 | RF-85 |
| PATCH | `/notificaciones/me/:id/leer` | 🔵🔴🟢 | RF-85 |
| PATCH | `/notificaciones/me/leer-todas` | 🔵🔴🟢 | RF-85 |
| GET | `/notificaciones/config` | 🔵 | RF-83 |
| PATCH | `/notificaciones/config` | 🔵 | RF-83 |
| GET | `/notificaciones/config-automatica` | 🟢 | RF-80 |
| PATCH | `/notificaciones/config-automatica` | 🟢 | RF-80 |

**Total: 63 endpoints · 85 RF cubiertos**

---

*Smart Training App · Diseño de la API REST · Versión 1.0 · Junio 2026*
