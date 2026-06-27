# Smart Training — G1: Autenticación y Sesiones
### Instrucciones para Claude Code

---

## Contexto

Continuación del monorepo Smart Training. El Grupo 0 está completo: NestJS corre en `localhost:3000/v1`, la PWA en `localhost:5173`, Prisma está conectado a PostgreSQL local con schema vacío, y los 10 módulos de dominio existen como esqueletos.

Este grupo implementa todo el sistema de autenticación: registro, login, 2FA para el gerente, recuperación de contraseña, guards de roles, y las pantallas de auth en el frontend.

**RF cubiertos:** RF-01 al RF-10  
**RN que aplican:** RN-001, RN-002, RN-008

---

## Reglas de trabajo

1. **Detente después de cada actividad** y reporta el checklist completo antes de continuar.
2. **No instales dependencias no listadas.** Si crees que falta algo, pregunta.
3. **No crees archivos fuera de la estructura definida.**
4. **No inicies la siguiente actividad** si algún ítem del checklist anterior falló.
5. **No implementes lógica de grupos futuros.** Por ejemplo: no crees el modelo `Membresia` aunque el registro de CLIENTE lo vaya a necesitar después — eso es G6.
6. **El 2FA aplica exclusivamente al rol GERENTE.** CLIENTE e INSTRUCTOR nunca pasan por ese flujo.
7. Si un comando falla, reporta el error completo antes de intentar resolverlo.

---

## A1.1 — Schema Prisma: Usuario, Sesion, RecuperacionPassword

### Qué se construye

Tres modelos en `prisma/schema.prisma` más todos los enums del sistema. Los enums se definen todos ahora aunque no todos se usen en G1, porque Prisma los necesita completos para las migraciones futuras.

### Decisiones tomadas — no preguntar

- `passwordHash` nunca se devuelve en ninguna respuesta de la API — se excluye siempre en las queries de Prisma con `select` explícito
- `ultimoAcceso` se actualiza en cada login exitoso
- `activo: Boolean` y `estado: EstadoUsuario` coexisten: `activo` es el flag rápido de acceso, `estado` tiene la razón (SUSPENDIDO, MOROSO)
- El campo `totp_secret` del gerente va en el modelo `Usuario` como `totpSecret String?` — nullable porque solo el gerente lo tiene
- `Sesion` almacena el refresh token hasheado, no el token en texto plano

### Contenido completo de `prisma/schema.prisma`

Reemplazar el contenido actual del archivo con:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ─── ENUMS ────────────────────────────────────────────────────────────────────

enum Rol {
  CLIENTE
  INSTRUCTOR
  GERENTE
}

enum EstadoUsuario {
  ACTIVO
  SUSPENDIDO
  MOROSO
}

enum TipoPlan {
  DIARIO
  SEMANAL
  QUINCENAL
  MENSUAL
  TRIMESTRAL
}

enum TarifaEspecial {
  ALCALDIA
  TORTAS_POWER
}

enum EstadoMembresia {
  ACTIVA
  INACTIVA
  CONGELADA
}

enum ConceptoPago {
  MENSUALIDAD
  INSCRIPCION
  RENOVACION
  PLAN_PERSONALIZADO
  PROMOCION
  MULTA
  PRODUCTO
  OTRO
}

enum MetodoPago {
  EFECTIVO
  TRANSFERENCIA
  TARJETA_CREDITO
  TARJETA_DEBITO
  NEQUI
  DAVIPLATA
  PAYPAL
  OTRO
}

enum EstadoPago {
  PENDIENTE
  PAGADO
  VENCIDO
  CANCELADO
  REEMBOLSADO
}

enum ObjetivoPerfil {
  GANAR_MASA_MUSCULAR
  PERDER_GRASA
  MEJORAR_CONDICION_FISICA
  AUMENTAR_FUERZA
  TONIFICAR
  RECOMPOSICION_CORPORAL
  MEJORAR_MOVILIDAD
  REHABILITACION
  OTRO
}

enum NivelFitness {
  PRINCIPIANTE
  INTERMEDIO
  AVANZADO
  ATLETA
}

enum Genero {
  MASCULINO
  FEMENINO
  OTRO
}

enum GrupoMuscular {
  PECHO
  ESPALDA
  HOMBROS
  BICEPS
  TRICEPS
  ANTEBRAZO
  CUADRICEPS
  FEMORALES
  GLUTEOS
  PANTORRILLAS
  ABDOMEN
  CORE
  CARDIO
  CUERPO_COMPLETO
  MOVILIDAD
}

enum DiaSemana {
  LUNES
  MARTES
  MIERCOLES
  JUEVES
  VIERNES
  SABADO
  DOMINGO
}

enum TipoNotificacion {
  RECORDATORIO_ENTRENAMIENTO
  NUEVA_RUTINA
  MEMBRESIA_PROXIMA_VENCER
  PAGO_VENCIDO
}

enum CanalNotificacion {
  PUSH
  EMAIL
  SMS
  INAPP
}

enum EstadoNotificacion {
  PENDIENTE
  ENVIADA
  LEIDA
  ERROR
  CANCELADA
}

enum CategoriaIngreso {
  MEMBRESIAS
  INSCRIPCIONES
  PLANES_PERSONALIZADOS
  PRODUCTOS
  PROMOCIONES
  OTROS
}

enum CategoriaEgreso {
  ARRIENDO
  SERVICIOS
  SALARIOS
  MANTENIMIENTO
  INSUMOS
  MARKETING
  EQUIPAMIENTO
  IMPUESTOS
  OTROS
}

enum EstadoMaquina {
  DISPONIBLE
  MANTENIMIENTO
  FUERA_DE_SERVICIO
}

enum ObjetivoEntrenamiento {
  FUERZA
  VOLUMEN
  PERDIDA_PESO
  RESISTENCIA
  OTRO
}

// ─── MODELOS G1 ───────────────────────────────────────────────────────────────

model Usuario {
  id              String        @id @default(uuid())
  nombre          String
  apellido        String
  correo          String        @unique
  telefono        String
  fechaNacimiento String?
  fotoPerfil      String?
  passwordHash    String
  totpSecret      String?       // solo GERENTE con 2FA activo
  rol             Rol           @default(CLIENTE)
  estado          EstadoUsuario @default(ACTIVO)
  activo          Boolean       @default(true)
  fechaRegistro   DateTime      @default(now())
  ultimoAcceso    DateTime?

  sesiones        Sesion[]
  recuperaciones  RecuperacionPassword[]

  @@map("usuarios")
}

model Sesion {
  id              String   @id @default(uuid())
  usuarioId       String
  tokenHash       String   @unique  // refresh token hasheado con bcrypt
  fechaInicio     DateTime @default(now())
  fechaExpiracion DateTime
  dispositivo     String?
  activa          Boolean  @default(true)

  usuario         Usuario  @relation(fields: [usuarioId], references: [id], onDelete: Cascade)

  @@map("sesiones")
}

model RecuperacionPassword {
  id         String   @id @default(uuid())
  usuarioId  String
  tokenHash  String   @unique  // token hasheado con bcrypt
  expiracion DateTime
  utilizado  Boolean  @default(false)

  usuario    Usuario  @relation(fields: [usuarioId], references: [id], onDelete: Cascade)

  @@map("recuperacion_passwords")
}
```

### Comandos a ejecutar

```bash
# Desde apps/api/
npx prisma migrate dev --name g1-auth-schema
npx prisma generate
```

### Checklist de verificación A1.1

- [ ] `prisma migrate dev` aplica sin errores
- [ ] Las tablas `usuarios`, `sesiones`, `recuperacion_passwords` existen en PostgreSQL
- [ ] El enum `Rol` contiene exactamente: `CLIENTE`, `INSTRUCTOR`, `GERENTE`
- [ ] El enum `EstadoUsuario` contiene exactamente: `ACTIVO`, `SUSPENDIDO`, `MOROSO`
- [ ] `npx prisma studio` abre y muestra los tres modelos correctamente

**Detente y reporta antes de continuar con A1.2.**

---

## A1.2 — Backend: Endpoints de autenticación

### Qué se construye

Implementación completa del `AuthModule`: 7 endpoints, lógica de negocio de autenticación, integración con Redis para refresh tokens, integración con Resend para emails, y soporte de TOTP para el gerente.

### Decisiones tomadas — no preguntar

- El access token dura `JWT_EXPIRES_IN` (15m por defecto), el refresh token dura `JWT_REFRESH_EXPIRES_IN` (7d)
- El refresh token se guarda **hasheado** en la tabla `Sesion` — nunca en texto plano
- Redis almacena los refresh tokens inválidos (blacklist) con TTL igual al tiempo restante del token
- El endpoint `POST /auth/recuperar-password` siempre responde `200` aunque el correo no exista (no revela si un correo está registrado)
- El token de recuperación de contraseña expira en 1 hora
- El TOTP del gerente usa el algoritmo SHA1, 6 dígitos, ventana de 1 paso (30 segundos)
- Al registrar un CLIENTE, **no** se crea membresía (eso es G6) — solo se crea el `Usuario` con `rol: CLIENTE`
- Al registrar un INSTRUCTOR, tampoco se crea membresía (RN-008)
- El endpoint de registro es solo para CLIENTE desde el frontend — INSTRUCTOR y GERENTE los crea el admin directamente en BD por ahora (se expone en G5)
- `POST /auth/logout` recibe el refresh token en el body, lo invalida en Redis y desactiva la `Sesion` en BD

### Estructura de archivos a crear

```
apps/api/src/auth/
├── auth.module.ts
├── auth.controller.ts
├── auth.service.ts
├── dto/
│   ├── registro.dto.ts
│   ├── login.dto.ts
│   ├── verificar-2fa.dto.ts
│   ├── refresh.dto.ts
│   ├── recuperar-password.dto.ts
│   └── reset-password.dto.ts
├── strategies/
│   ├── jwt.strategy.ts
│   └── local.strategy.ts
└── interfaces/
    └── jwt-payload.interface.ts
```

### Contenido de los archivos

**`auth/interfaces/jwt-payload.interface.ts`:**
```typescript
export interface JwtPayload {
  sub: string;      // usuarioId
  rol: string;      // Rol enum value
  iat?: number;
  exp?: number;
}
```

**`auth/dto/registro.dto.ts`:**
```typescript
import { IsEmail, IsString, MinLength, MaxLength, Matches } from 'class-validator';

export class RegistroDto {
  @IsString()
  @MinLength(2)
  @MaxLength(50)
  nombre: string;

  @IsString()
  @MinLength(2)
  @MaxLength(50)
  apellido: string;

  @IsEmail()
  correo: string;

  @IsString()
  @Matches(/^[0-9]{7,15}$/, { message: 'Teléfono debe contener entre 7 y 15 dígitos' })
  telefono: string;

  @IsString()
  @MinLength(8)
  @MaxLength(100)
  password: string;
}
```

**`auth/dto/login.dto.ts`:**
```typescript
import { IsEmail, IsString } from 'class-validator';

export class LoginDto {
  @IsEmail()
  correo: string;

  @IsString()
  password: string;
}
```

**`auth/dto/verificar-2fa.dto.ts`:**
```typescript
import { IsString, IsUUID, Length } from 'class-validator';

export class Verificar2FADto {
  @IsUUID()
  usuarioId: string;

  @IsString()
  @Length(6, 6)
  codigo: string;
}
```

**`auth/dto/refresh.dto.ts`:**
```typescript
import { IsString } from 'class-validator';

export class RefreshDto {
  @IsString()
  refreshToken: string;
}
```

**`auth/dto/recuperar-password.dto.ts`:**
```typescript
import { IsEmail } from 'class-validator';

export class RecuperarPasswordDto {
  @IsEmail()
  correo: string;
}
```

**`auth/dto/reset-password.dto.ts`:**
```typescript
import { IsString, MinLength } from 'class-validator';

export class ResetPasswordDto {
  @IsString()
  token: string;

  @IsString()
  @MinLength(8)
  nuevaPassword: string;
}
```

**`auth/strategies/jwt.strategy.ts`:**
```typescript
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { JwtPayload } from './interfaces/jwt-payload.interface';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private config: ConfigService,
    private prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: config.get<string>('JWT_SECRET'),
    });
  }

  async validate(payload: JwtPayload) {
    const usuario = await this.prisma.usuario.findUnique({
      where: { id: payload.sub },
      select: { id: true, rol: true, activo: true, estado: true },
    });

    if (!usuario || !usuario.activo) {
      throw new UnauthorizedException();
    }

    return { usuarioId: usuario.id, rol: usuario.rol };
  }
}
```

**`auth/auth.service.ts`:**
```typescript
import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcryptjs';
import * as speakeasy from 'speakeasy';
import { Resend } from 'resend';
import { RegistroDto } from './dto/registro.dto';
import { LoginDto } from './dto/login.dto';
import { JwtPayload } from './interfaces/jwt-payload.interface';
import { Rol } from '@prisma/client';

@Injectable()
export class AuthService {
  private resend: Resend;

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private config: ConfigService,
  ) {
    this.resend = new Resend(this.config.get('RESEND_API_KEY'));
  }

  // ── Registro ─────────────────────────────────────────────────────────────

  async registro(dto: RegistroDto) {
    const existe = await this.prisma.usuario.findUnique({
      where: { correo: dto.correo },
    });
    if (existe) throw new ConflictException('CORREO_YA_REGISTRADO');

    const passwordHash = await bcrypt.hash(dto.password, 12);

    const usuario = await this.prisma.usuario.create({
      data: {
        nombre: dto.nombre,
        apellido: dto.apellido,
        correo: dto.correo,
        telefono: dto.telefono,
        passwordHash,
        rol: Rol.CLIENTE,
      },
      select: { id: true, correo: true },
    });

    const tokens = await this.generarTokens(usuario.id, Rol.CLIENTE);

    return {
      usuarioId: usuario.id,
      correo: usuario.correo,
      ...tokens,
    };
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  async login(dto: LoginDto) {
    const usuario = await this.prisma.usuario.findUnique({
      where: { correo: dto.correo },
      select: {
        id: true,
        passwordHash: true,
        rol: true,
        activo: true,
        estado: true,
        totpSecret: true,
      },
    });

    if (!usuario) throw new UnauthorizedException('CREDENCIALES_INVALIDAS');

    const passwordValida = await bcrypt.compare(dto.password, usuario.passwordHash);
    if (!passwordValida) throw new UnauthorizedException('CREDENCIALES_INVALIDAS');

    if (!usuario.activo) throw new UnauthorizedException('USUARIO_INACTIVO');

    // Actualizar último acceso
    await this.prisma.usuario.update({
      where: { id: usuario.id },
      data: { ultimoAcceso: new Date() },
    });

    // Gerente con 2FA: devolver indicador sin tokens
    if (usuario.rol === Rol.GERENTE && usuario.totpSecret) {
      return {
        usuarioId: usuario.id,
        rol: usuario.rol,
        requiere2FA: true,
        accessToken: null,
        refreshToken: null,
      };
    }

    const tokens = await this.generarTokens(usuario.id, usuario.rol);

    return {
      usuarioId: usuario.id,
      rol: usuario.rol,
      requiere2FA: false,
      ...tokens,
    };
  }

  // ── 2FA ──────────────────────────────────────────────────────────────────

  async verificar2FA(usuarioId: string, codigo: string) {
    const usuario = await this.prisma.usuario.findUnique({
      where: { id: usuarioId },
      select: { id: true, rol: true, totpSecret: true },
    });

    if (!usuario || !usuario.totpSecret) {
      throw new UnauthorizedException('2FA_NO_CONFIGURADO');
    }

    const valido = speakeasy.totp.verify({
      secret: usuario.totpSecret,
      encoding: 'base32',
      token: codigo,
      window: 1,
    });

    if (!valido) throw new UnauthorizedException('CODIGO_2FA_INVALIDO');

    return this.generarTokens(usuario.id, usuario.rol);
  }

  // ── Refresh token ─────────────────────────────────────────────────────────

  async refresh(refreshToken: string) {
    let payload: JwtPayload;
    try {
      payload = this.jwtService.verify(refreshToken, {
        secret: this.config.get('JWT_REFRESH_SECRET'),
      });
    } catch {
      throw new UnauthorizedException('REFRESH_TOKEN_INVALIDO');
    }

    // Buscar la sesión activa con este token
    const sesiones = await this.prisma.sesion.findMany({
      where: { usuarioId: payload.sub, activa: true },
    });

    let sesionValida = null;
    for (const sesion of sesiones) {
      const coincide = await bcrypt.compare(refreshToken, sesion.tokenHash);
      if (coincide) {
        sesionValida = sesion;
        break;
      }
    }

    if (!sesionValida) throw new UnauthorizedException('REFRESH_TOKEN_INVALIDO');

    const usuario = await this.prisma.usuario.findUnique({
      where: { id: payload.sub },
      select: { id: true, rol: true, activo: true },
    });

    if (!usuario || !usuario.activo) throw new UnauthorizedException();

    const accessToken = this.generarAccessToken(usuario.id, usuario.rol);
    return { accessToken };
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  async logout(refreshToken: string) {
    let payload: JwtPayload;
    try {
      payload = this.jwtService.verify(refreshToken, {
        secret: this.config.get('JWT_REFRESH_SECRET'),
      });
    } catch {
      // Token inválido o expirado — igual se considera logout exitoso
      return;
    }

    const sesiones = await this.prisma.sesion.findMany({
      where: { usuarioId: payload.sub, activa: true },
    });

    for (const sesion of sesiones) {
      const coincide = await bcrypt.compare(refreshToken, sesion.tokenHash);
      if (coincide) {
        await this.prisma.sesion.update({
          where: { id: sesion.id },
          data: { activa: false },
        });
        break;
      }
    }
  }

  // ── Recuperar contraseña ──────────────────────────────────────────────────

  async recuperarPassword(correo: string) {
    const usuario = await this.prisma.usuario.findUnique({
      where: { correo },
      select: { id: true, nombre: true },
    });

    // Siempre responde exitosamente — no revelar si el correo existe
    if (!usuario) return;

    const token = this.generarTokenAleatorio();
    const tokenHash = await bcrypt.hash(token, 10);
    const expiracion = new Date(Date.now() + 60 * 60 * 1000); // 1 hora

    // Invalidar tokens anteriores del mismo usuario
    await this.prisma.recuperacionPassword.updateMany({
      where: { usuarioId: usuario.id, utilizado: false },
      data: { utilizado: true },
    });

    await this.prisma.recuperacionPassword.create({
      data: { usuarioId: usuario.id, tokenHash, expiracion },
    });

    const resetUrl = `${this.config.get('FRONTEND_URL')}/reset-password?token=${token}`;

    await this.resend.emails.send({
      from: this.config.get('RESEND_FROM_EMAIL'),
      to: correo,
      subject: 'Recuperación de contraseña — Smart Training',
      html: `
        <p>Hola ${usuario.nombre},</p>
        <p>Haz clic en el siguiente enlace para restablecer tu contraseña:</p>
        <a href="${resetUrl}">${resetUrl}</a>
        <p>Este enlace expira en 1 hora.</p>
        <p>Si no solicitaste este cambio, ignora este correo.</p>
      `,
    });
  }

  async resetPassword(token: string, nuevaPassword: string) {
    // Buscar entre todos los tokens no utilizados y válidos
    const registros = await this.prisma.recuperacionPassword.findMany({
      where: { utilizado: false, expiracion: { gt: new Date() } },
    });

    let registroValido = null;
    for (const registro of registros) {
      const coincide = await bcrypt.compare(token, registro.tokenHash);
      if (coincide) {
        registroValido = registro;
        break;
      }
    }

    if (!registroValido) throw new BadRequestException('TOKEN_INVALIDO_O_EXPIRADO');

    const passwordHash = await bcrypt.hash(nuevaPassword, 12);

    await this.prisma.$transaction([
      this.prisma.usuario.update({
        where: { id: registroValido.usuarioId },
        data: { passwordHash },
      }),
      this.prisma.recuperacionPassword.update({
        where: { id: registroValido.id },
        data: { utilizado: true },
      }),
      // Invalidar todas las sesiones activas del usuario
      this.prisma.sesion.updateMany({
        where: { usuarioId: registroValido.usuarioId },
        data: { activa: false },
      }),
    ]);
  }

  // ── Helpers privados ──────────────────────────────────────────────────────

  private async generarTokens(usuarioId: string, rol: string) {
    const accessToken = this.generarAccessToken(usuarioId, rol);
    const refreshToken = this.generarRefreshToken(usuarioId, rol);

    const tokenHash = await bcrypt.hash(refreshToken, 10);
    const diasExpiracion = parseInt(
      this.config.get('JWT_REFRESH_EXPIRES_IN', '7').replace('d', ''),
    );
    const fechaExpiracion = new Date();
    fechaExpiracion.setDate(fechaExpiracion.getDate() + diasExpiracion);

    await this.prisma.sesion.create({
      data: {
        usuarioId,
        tokenHash,
        fechaExpiracion,
      },
    });

    return { accessToken, refreshToken };
  }

  private generarAccessToken(usuarioId: string, rol: string): string {
    const payload: JwtPayload = { sub: usuarioId, rol };
    return this.jwtService.sign(payload, {
      secret: this.config.get('JWT_SECRET'),
      expiresIn: this.config.get('JWT_EXPIRES_IN', '15m'),
    });
  }

  private generarRefreshToken(usuarioId: string, rol: string): string {
    const payload: JwtPayload = { sub: usuarioId, rol };
    return this.jwtService.sign(payload, {
      secret: this.config.get('JWT_REFRESH_SECRET'),
      expiresIn: this.config.get('JWT_REFRESH_EXPIRES_IN', '7d'),
    });
  }

  private generarTokenAleatorio(): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    for (let i = 0; i < 64; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }
}
```

**`auth/auth.controller.ts`:**
```typescript
import {
  Controller,
  Post,
  Body,
  HttpCode,
  HttpStatus,
  UseGuards,
  Request,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegistroDto } from './dto/registro.dto';
import { LoginDto } from './dto/login.dto';
import { Verificar2FADto } from './dto/verificar-2fa.dto';
import { RefreshDto } from './dto/refresh.dto';
import { RecuperarPasswordDto } from './dto/recuperar-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('registro')
  @HttpCode(HttpStatus.CREATED)
  async registro(@Body() dto: RegistroDto) {
    const data = await this.authService.registro(dto);
    return { ok: true, data };
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() dto: LoginDto) {
    const data = await this.authService.login(dto);
    return { ok: true, data };
  }

  @Post('2fa/verificar')
  @HttpCode(HttpStatus.OK)
  async verificar2FA(@Body() dto: Verificar2FADto) {
    const data = await this.authService.verificar2FA(dto.usuarioId, dto.codigo);
    return { ok: true, data };
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(@Body() dto: RefreshDto) {
    const data = await this.authService.refresh(dto.refreshToken);
    return { ok: true, data };
  }

  @Post('recuperar-password')
  @HttpCode(HttpStatus.OK)
  async recuperarPassword(@Body() dto: RecuperarPasswordDto) {
    await this.authService.recuperarPassword(dto.correo);
    return {
      ok: true,
      data: { message: 'Si el correo existe, recibirás un enlace en los próximos minutos.' },
    };
  }

  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  async resetPassword(@Body() dto: ResetPasswordDto) {
    await this.authService.resetPassword(dto.token, dto.nuevaPassword);
    return { ok: true, data: { message: 'Contraseña actualizada correctamente.' } };
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(@Body() dto: RefreshDto) {
    await this.authService.logout(dto.refreshToken);
  }
}
```

**`auth/auth.module.ts`:**
```typescript
import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtStrategy } from './strategies/jwt.strategy';

@Module({
  imports: [
    PassportModule,
    JwtModule.register({}), // configuración dinámica vía ConfigService en el service
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy],
  exports: [AuthService],
})
export class AuthModule {}
```

### Variable de entorno a agregar en `.env`

```env
FRONTEND_URL="http://localhost:5173"
```

Y en `.env.example`:
```env
# URL del frontend (para links en emails)
FRONTEND_URL=""
```

### Checklist de verificación A1.2

Probar con curl o Postman:

```bash
# Registro exitoso
curl -X POST http://localhost:3000/v1/auth/registro \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Carlos","apellido":"Ramirez","correo":"carlos@test.com","telefono":"3001234567","password":"Password123"}'
# Debe responder 201 con usuarioId, accessToken y refreshToken

# Registro con correo duplicado
# (ejecutar el mismo comando anterior)
# Debe responder 409

# Login correcto
curl -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"correo":"carlos@test.com","password":"Password123"}'
# Debe responder 200 con requiere2FA: false y los tokens

# Login con password incorrecta
curl -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"correo":"carlos@test.com","password":"incorrecta"}'
# Debe responder 401

# Recuperar password con correo inexistente
curl -X POST http://localhost:3000/v1/auth/recuperar-password \
  -H "Content-Type: application/json" \
  -d '{"correo":"noexiste@test.com"}'
# Debe responder 200 (no revela si el correo existe)

# Logout
curl -X POST http://localhost:3000/v1/auth/logout \
  -H "Authorization: Bearer ACCESS_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{"refreshToken":"REFRESH_TOKEN_AQUI"}'
# Debe responder 204

# Refresh con token invalidado (después del logout)
curl -X POST http://localhost:3000/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken":"REFRESH_TOKEN_USADO_EN_LOGOUT"}'
# Debe responder 401
```

- [ ] `POST /auth/registro` crea el usuario y devuelve `201` con tokens
- [ ] El usuario creado tiene `passwordHash` en BD — nunca la contraseña en texto plano (verificar con `prisma studio`)
- [ ] `POST /auth/login` con credenciales correctas devuelve `200` con `requiere2FA: false`
- [ ] `POST /auth/login` con credenciales incorrectas devuelve `401`
- [ ] `POST /auth/recuperar-password` con correo inexistente devuelve `200`
- [ ] `POST /auth/logout` devuelve `204` y la sesión queda con `activa: false` en BD
- [ ] `POST /auth/refresh` con token ya usado en logout devuelve `401`

**Detente y reporta antes de continuar con A1.3.**

---

## A1.3 — Backend: Guards de roles

### Qué se construye

Guards reutilizables que protegen rutas por autenticación y por rol. Se crean en `src/common/` para que todos los módulos los puedan importar.

### Estructura de archivos a crear

```
apps/api/src/common/
├── guards/
│   ├── jwt-auth.guard.ts
│   └── roles.guard.ts
├── decorators/
│   ├── roles.decorator.ts
│   └── usuario-actual.decorator.ts
└── common.module.ts
```

### Contenido de los archivos

**`common/guards/jwt-auth.guard.ts`:**
```typescript
import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}
```

**`common/guards/roles.guard.ts`:**
```typescript
import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { Rol } from '@prisma/client';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const rolesRequeridos = this.reflector.getAllAndOverride<Rol[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!rolesRequeridos || rolesRequeridos.length === 0) return true;

    const { user } = context.switchToHttp().getRequest();

    if (!rolesRequeridos.includes(user.rol)) {
      throw new ForbiddenException('ACCESO_DENEGADO');
    }

    return true;
  }
}
```

**`common/decorators/roles.decorator.ts`:**
```typescript
import { SetMetadata } from '@nestjs/common';
import { Rol } from '@prisma/client';

export const ROLES_KEY = 'roles';
export const Roles = (...roles: Rol[]) => SetMetadata(ROLES_KEY, roles);
```

**`common/decorators/usuario-actual.decorator.ts`:**
```typescript
import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export const UsuarioActual = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);
```

**`common/common.module.ts`:**
```typescript
import { Module } from '@nestjs/common';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { RolesGuard } from './guards/roles.guard';

@Module({
  providers: [JwtAuthGuard, RolesGuard],
  exports: [JwtAuthGuard, RolesGuard],
})
export class CommonModule {}
```

### Endpoint de prueba para los guards

Agregar temporalmente en `app.controller.ts` estos endpoints de prueba — se eliminarán al verificar:

```typescript
import { Controller, Get, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { RolesGuard } from './common/guards/roles.guard';
import { Roles } from './common/decorators/roles.decorator';
import { UsuarioActual } from './common/decorators/usuario-actual.decorator';
import { Rol } from '@prisma/client';

@Controller()
export class AppController {
  @Get()
  healthCheck() {
    return { ok: true, service: 'Smart Training API', version: '1.0.0', timestamp: new Date().toISOString() };
  }

  // Endpoint de prueba — eliminar después de verificar A1.3
  @Get('test/protegido')
  @UseGuards(JwtAuthGuard)
  testProtegido(@UsuarioActual() usuario: any) {
    return { ok: true, data: { mensaje: 'Ruta protegida', usuario } };
  }

  // Endpoint de prueba — eliminar después de verificar A1.3
  @Get('test/solo-gerente')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Rol.GERENTE)
  testSoloGerente() {
    return { ok: true, data: { mensaje: 'Solo gerentes' } };
  }
}
```

### Registrar CommonModule en AppModule

Agregar `CommonModule` en los imports de `app.module.ts`.

### Checklist de verificación A1.3

```bash
# Sin token — debe dar 401
curl http://localhost:3000/v1/test/protegido
# Respuesta: 401

# Con token de CLIENTE en endpoint de GERENTE — debe dar 403
curl http://localhost:3000/v1/test/solo-gerente \
  -H "Authorization: Bearer TOKEN_DE_CLIENTE"
# Respuesta: 403

# Con token de CLIENTE en endpoint protegido — debe dar 200
curl http://localhost:3000/v1/test/protegido \
  -H "Authorization: Bearer TOKEN_DE_CLIENTE"
# Respuesta: 200 con usuarioId y rol en data
```

- [ ] Sin token devuelve `401`
- [ ] Token de CLIENTE en ruta de GERENTE devuelve `403`
- [ ] Token de CLIENTE en ruta protegida devuelve `200`
- [ ] El payload del usuario disponible en el controlador contiene `usuarioId` y `rol`
- [ ] Eliminar los endpoints de prueba de `app.controller.ts` después de verificar

**Detente y reporta antes de continuar con A1.4.**

---

## A1.4 — Frontend: Flujo de login y registro

### Qué se construye

Pantallas de login, registro (2 pasos), recuperación de contraseña y verificación 2FA. Store de autenticación con Zustand. Interceptor de Axios con refresh automático. Rutas protegidas por rol.

### Decisiones tomadas — no preguntar

- El estado de autenticación vive en Zustand (`store/auth.store.ts`)
- El `accessToken` se guarda en memoria (variable de Zustand) — no en localStorage ni sessionStorage
- El `refreshToken` se guarda en `localStorage` — persiste entre sesiones
- El refresh automático del accessToken usa el interceptor de Axios ya creado en G0
- Las rutas protegidas usan un componente `<RutaProtegida>` que verifica el rol
- El diseño de las pantallas es funcional y limpio — no necesita ser el diseño final
- El paso 2 del registro (perfil físico: objetivo, género, nivel) llama a `PATCH /usuarios/me/perfil-fisico` — este endpoint se implementa en G2; por ahora el paso 2 se puede mostrar pero el submit lleva directo al dashboard

### Dependencias a instalar

```bash
# Desde apps/web/
pnpm add zustand
```

### Estructura de archivos a crear

```
apps/web/src/
├── store/
│   └── auth.store.ts
├── hooks/
│   └── useAuth.ts           ← reemplazar el vacío de G0
├── components/
│   └── auth/
│       ├── RutaProtegida.tsx
│       └── RedireccionarSegunRol.tsx
└── pages/
    └── auth/
        ├── LoginPage.tsx
        ├── RegistroPage.tsx
        ├── RecuperarPasswordPage.tsx
        ├── ResetPasswordPage.tsx
        └── Verificar2FAPage.tsx
```

### Contenido de los archivos

**`store/auth.store.ts`:**
```typescript
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface Usuario {
  id: string;
  rol: 'CLIENTE' | 'INSTRUCTOR' | 'GERENTE';
}

interface AuthState {
  accessToken: string | null;
  usuario: Usuario | null;
  setTokens: (accessToken: string, usuario: Usuario) => void;
  setAccessToken: (token: string) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      accessToken: null,
      usuario: null,
      setTokens: (accessToken, usuario) => set({ accessToken, usuario }),
      setAccessToken: (token) => set({ accessToken: token }),
      logout: () => set({ accessToken: null, usuario: null }),
    }),
    {
      name: 'smart-training-auth',
      // Solo persistir el usuario — el accessToken se refresca al reabrir
      partialize: (state) => ({ usuario: state.usuario }),
    },
  ),
);
```

**`services/api.ts`** (reemplazar el de G0 con la versión con refresh automático):
```typescript
import axios from 'axios';

const BASE_URL = import.meta.env.VITE_API_URL || '/v1';

export const apiClient = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json' },
});

// Agrega el accessToken a cada petición
apiClient.interceptors.request.use(
  (config) => {
    // Importar dinámicamente para evitar dependencia circular con el store
    const store = (window as any).__authStore;
    const token = store?.getState?.()?.accessToken;
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error),
);

// Refresh automático cuando expira el accessToken
let refrescando = false;
let cola: Array<(token: string) => void> = [];

apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const solicitudOriginal = error.config;

    if (error.response?.status !== 401 || solicitudOriginal._reintentado) {
      return Promise.reject(error);
    }

    solicitudOriginal._reintentado = true;

    if (refrescando) {
      return new Promise((resolve) => {
        cola.push((token: string) => {
          solicitudOriginal.headers.Authorization = `Bearer ${token}`;
          resolve(apiClient(solicitudOriginal));
        });
      });
    }

    refrescando = true;

    try {
      const refreshToken = localStorage.getItem('refreshToken');
      if (!refreshToken) throw new Error('Sin refresh token');

      const { data } = await axios.post(`${BASE_URL}/auth/refresh`, { refreshToken });
      const nuevoToken = data.data.accessToken;

      const store = (window as any).__authStore;
      store?.getState?.()?.setAccessToken(nuevoToken);

      cola.forEach((cb) => cb(nuevoToken));
      cola = [];

      solicitudOriginal.headers.Authorization = `Bearer ${nuevoToken}`;
      return apiClient(solicitudOriginal);
    } catch {
      localStorage.removeItem('refreshToken');
      const store = (window as any).__authStore;
      store?.getState?.()?.logout();
      window.location.href = '/login';
      return Promise.reject(error);
    } finally {
      refrescando = false;
    }
  },
);

export default apiClient;
```

**`hooks/useAuth.ts`:**
```typescript
import { useAuthStore } from '../store/auth.store';
import { useNavigate } from 'react-router-dom';
import apiClient from '../services/api';

export function useAuth() {
  const { accessToken, usuario, setTokens, logout: logoutStore } = useAuthStore();
  const navigate = useNavigate();

  const login = async (correo: string, password: string) => {
    const { data } = await apiClient.post('/auth/login', { correo, password });
    const res = data.data;

    if (res.requiere2FA) {
      return { requiere2FA: true, usuarioId: res.usuarioId };
    }

    localStorage.setItem('refreshToken', res.refreshToken);
    setTokens(res.accessToken, { id: res.usuarioId, rol: res.rol });
    return { requiere2FA: false, rol: res.rol };
  };

  const registro = async (datos: {
    nombre: string;
    apellido: string;
    correo: string;
    telefono: string;
    password: string;
  }) => {
    const { data } = await apiClient.post('/auth/registro', datos);
    const res = data.data;
    localStorage.setItem('refreshToken', res.refreshToken);
    setTokens(res.accessToken, { id: res.usuarioId, rol: 'CLIENTE' });
  };

  const verificar2FA = async (usuarioId: string, codigo: string) => {
    const { data } = await apiClient.post('/auth/2fa/verificar', { usuarioId, codigo });
    const res = data.data;
    localStorage.setItem('refreshToken', res.refreshToken);
    setTokens(res.accessToken, { id: usuarioId, rol: 'GERENTE' });
  };

  const logout = async () => {
    const refreshToken = localStorage.getItem('refreshToken');
    if (refreshToken) {
      try {
        await apiClient.post('/auth/logout', { refreshToken });
      } catch {
        // logout local aunque falle el servidor
      }
    }
    localStorage.removeItem('refreshToken');
    logoutStore();
    navigate('/login');
  };

  const rutaPorRol = (rol: string) => {
    if (rol === 'GERENTE') return '/gerente';
    if (rol === 'INSTRUCTOR') return '/admin';
    return '/usuario';
  };

  return { accessToken, usuario, login, registro, verificar2FA, logout, rutaPorRol };
}
```

**`components/auth/RutaProtegida.tsx`:**
```typescript
import { Navigate } from 'react-router-dom';
import { useAuthStore } from '../../store/auth.store';

interface Props {
  children: React.ReactNode;
  roles?: Array<'CLIENTE' | 'INSTRUCTOR' | 'GERENTE'>;
}

export function RutaProtegida({ children, roles }: Props) {
  const { usuario } = useAuthStore();

  if (!usuario) return <Navigate to="/login" replace />;

  if (roles && !roles.includes(usuario.rol as any)) {
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
}
```

**`pages/auth/LoginPage.tsx`:**
```tsx
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';

export default function LoginPage() {
  const [correo, setCorreo] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [cargando, setCargando] = useState(false);
  const { login, rutaPorRol } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setCargando(true);
    try {
      const resultado = await login(correo, password);
      if (resultado.requiere2FA) {
        navigate(`/auth/2fa?usuarioId=${resultado.usuarioId}`);
      } else {
        navigate(rutaPorRol(resultado.rol!));
      }
    } catch {
      setError('Correo o contraseña incorrectos.');
    } finally {
      setCargando(false);
    }
  };

  return (
    <div className="min-h-screen bg-surface flex items-center justify-center p-4">
      <div className="w-full max-w-md bg-surface-card rounded-2xl p-8 shadow-xl">
        <h1 className="text-2xl font-bold text-white mb-2">Iniciar sesión</h1>
        <p className="text-slate-400 mb-8">Smart Training</p>

        <form onSubmit={handleSubmit} className="space-y-5">
          <div>
            <label className="block text-sm font-medium text-slate-300 mb-1">Correo</label>
            <input
              type="email"
              value={correo}
              onChange={(e) => setCorreo(e.target.value)}
              className="w-full bg-surface border border-surface-border rounded-lg px-4 py-3 text-white placeholder-slate-500 focus:outline-none focus:border-primary-500"
              placeholder="tu@correo.com"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-1">Contraseña</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full bg-surface border border-surface-border rounded-lg px-4 py-3 text-white placeholder-slate-500 focus:outline-none focus:border-primary-500"
              placeholder="••••••••"
              required
            />
          </div>

          {error && (
            <p className="text-red-400 text-sm">{error}</p>
          )}

          <button
            type="submit"
            disabled={cargando}
            className="w-full bg-primary-500 hover:bg-primary-600 disabled:opacity-50 text-white font-semibold py-3 rounded-lg transition-colors"
          >
            {cargando ? 'Ingresando...' : 'Ingresar'}
          </button>

          <div className="flex justify-between text-sm">
            <a href="/auth/registro" className="text-primary-500 hover:underline">
              Crear cuenta
            </a>
            <a href="/auth/recuperar-password" className="text-slate-400 hover:underline">
              Olvidé mi contraseña
            </a>
          </div>
        </form>
      </div>
    </div>
  );
}
```

**`pages/auth/RegistroPage.tsx`:**
```tsx
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';

export default function RegistroPage() {
  const [paso, setPaso] = useState(1);
  const [datos, setDatos] = useState({
    nombre: '', apellido: '', correo: '', telefono: '', password: '',
  });
  const [error, setError] = useState('');
  const [cargando, setCargando] = useState(false);
  const { registro } = useAuth();
  const navigate = useNavigate();

  const handlePaso1 = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setCargando(true);
    try {
      await registro(datos);
      setPaso(2);
    } catch (err: any) {
      if (err.response?.status === 409) {
        setError('Este correo ya está registrado.');
      } else {
        setError('Error al crear la cuenta. Intenta de nuevo.');
      }
    } finally {
      setCargando(false);
    }
  };

  // Paso 2: perfil físico — el endpoint se implementa en G2
  // Por ahora navega directamente al dashboard
  const handlePaso2 = (e: React.FormEvent) => {
    e.preventDefault();
    navigate('/usuario');
  };

  if (paso === 2) {
    return (
      <div className="min-h-screen bg-surface flex items-center justify-center p-4">
        <div className="w-full max-w-md bg-surface-card rounded-2xl p-8 shadow-xl">
          <h1 className="text-2xl font-bold text-white mb-2">Completa tu perfil</h1>
          <p className="text-slate-400 mb-8">Paso 2 de 2 — Esta información nos ayuda a personalizar tu experiencia</p>
          <form onSubmit={handlePaso2}>
            <p className="text-slate-400 text-sm mb-6">
              (La configuración del perfil físico se habilitará próximamente)
            </p>
            <button
              type="submit"
              className="w-full bg-primary-500 hover:bg-primary-600 text-white font-semibold py-3 rounded-lg transition-colors"
            >
              Ir al inicio
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-surface flex items-center justify-center p-4">
      <div className="w-full max-w-md bg-surface-card rounded-2xl p-8 shadow-xl">
        <h1 className="text-2xl font-bold text-white mb-2">Crear cuenta</h1>
        <p className="text-slate-400 mb-8">Paso 1 de 2</p>

        <form onSubmit={handlePaso1} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-1">Nombre</label>
              <input
                type="text"
                value={datos.nombre}
                onChange={(e) => setDatos({ ...datos, nombre: e.target.value })}
                className="w-full bg-surface border border-surface-border rounded-lg px-4 py-3 text-white focus:outline-none focus:border-primary-500"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-1">Apellido</label>
              <input
                type="text"
                value={datos.apellido}
                onChange={(e) => setDatos({ ...datos, apellido: e.target.value })}
                className="w-full bg-surface border border-surface-border rounded-lg px-4 py-3 text-white focus:outline-none focus:border-primary-500"
                required
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-1">Correo</label>
            <input
              type="email"
              value={datos.correo}
              onChange={(e) => setDatos({ ...datos, correo: e.target.value })}
              className="w-full bg-surface border border-surface-border rounded-lg px-4 py-3 text-white focus:outline-none focus:border-primary-500"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-1">Teléfono</label>
            <input
              type="tel"
              value={datos.telefono}
              onChange={(e) => setDatos({ ...datos, telefono: e.target.value })}
              className="w-full bg-surface border border-surface-border rounded-lg px-4 py-3 text-white focus:outline-none focus:border-primary-500"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-300 mb-1">Contraseña</label>
            <input
              type="password"
              value={datos.password}
              onChange={(e) => setDatos({ ...datos, password: e.target.value })}
              className="w-full bg-surface border border-surface-border rounded-lg px-4 py-3 text-white focus:outline-none focus:border-primary-500"
              minLength={8}
              required
            />
          </div>

          {error && <p className="text-red-400 text-sm">{error}</p>}

          <button
            type="submit"
            disabled={cargando}
            className="w-full bg-primary-500 hover:bg-primary-600 disabled:opacity-50 text-white font-semibold py-3 rounded-lg transition-colors"
          >
            {cargando ? 'Creando cuenta...' : 'Continuar'}
          </button>

          <p className="text-center text-slate-400 text-sm">
            ¿Ya tienes cuenta?{' '}
            <a href="/login" className="text-primary-500 hover:underline">Inicia sesión</a>
          </p>
        </form>
      </div>
    </div>
  );
}
```

**`pages/auth/Verificar2FAPage.tsx`:**
```tsx
import { useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';

export default function Verificar2FAPage() {
  const [codigo, setCodigo] = useState('');
  const [error, setError] = useState('');
  const [cargando, setCargando] = useState(false);
  const { verificar2FA } = useAuth();
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const usuarioId = params.get('usuarioId') || '';

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setCargando(true);
    try {
      await verificar2FA(usuarioId, codigo);
      navigate('/gerente');
    } catch {
      setError('Código incorrecto. Intenta de nuevo.');
    } finally {
      setCargando(false);
    }
  };

  return (
    <div className="min-h-screen bg-surface flex items-center justify-center p-4">
      <div className="w-full max-w-sm bg-surface-card rounded-2xl p-8 shadow-xl">
        <h1 className="text-2xl font-bold text-white mb-2">Verificación</h1>
        <p className="text-slate-400 mb-8">Ingresa el código de 6 dígitos de tu app autenticadora.</p>

        <form onSubmit={handleSubmit} className="space-y-5">
          <input
            type="text"
            value={codigo}
            onChange={(e) => setCodigo(e.target.value.replace(/\D/g, '').slice(0, 6))}
            className="w-full bg-surface border border-surface-border rounded-lg px-4 py-4 text-white text-center text-2xl tracking-widest focus:outline-none focus:border-primary-500"
            placeholder="000000"
            maxLength={6}
            required
          />

          {error && <p className="text-red-400 text-sm text-center">{error}</p>}

          <button
            type="submit"
            disabled={cargando || codigo.length !== 6}
            className="w-full bg-primary-500 hover:bg-primary-600 disabled:opacity-50 text-white font-semibold py-3 rounded-lg transition-colors"
          >
            {cargando ? 'Verificando...' : 'Verificar'}
          </button>
        </form>
      </div>
    </div>
  );
}
```

**`pages/auth/RecuperarPasswordPage.tsx`:**
```tsx
import { useState } from 'react';
import apiClient from '../../services/api';

export default function RecuperarPasswordPage() {
  const [correo, setCorreo] = useState('');
  const [enviado, setEnviado] = useState(false);
  const [cargando, setCargando] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setCargando(true);
    try {
      await apiClient.post('/auth/recuperar-password', { correo });
    } finally {
      setEnviado(true);
      setCargando(false);
    }
  };

  if (enviado) {
    return (
      <div className="min-h-screen bg-surface flex items-center justify-center p-4">
        <div className="w-full max-w-md bg-surface-card rounded-2xl p-8 text-center">
          <p className="text-white text-lg font-semibold mb-2">Revisa tu correo</p>
          <p className="text-slate-400">Si el correo está registrado, recibirás un enlace en los próximos minutos.</p>
          <a href="/login" className="mt-6 block text-primary-500 hover:underline">Volver al login</a>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-surface flex items-center justify-center p-4">
      <div className="w-full max-w-md bg-surface-card rounded-2xl p-8">
        <h1 className="text-2xl font-bold text-white mb-2">Recuperar contraseña</h1>
        <p className="text-slate-400 mb-8">Te enviaremos un enlace a tu correo.</p>

        <form onSubmit={handleSubmit} className="space-y-5">
          <input
            type="email"
            value={correo}
            onChange={(e) => setCorreo(e.target.value)}
            className="w-full bg-surface border border-surface-border rounded-lg px-4 py-3 text-white focus:outline-none focus:border-primary-500"
            placeholder="tu@correo.com"
            required
          />
          <button
            type="submit"
            disabled={cargando}
            className="w-full bg-primary-500 hover:bg-primary-600 disabled:opacity-50 text-white font-semibold py-3 rounded-lg"
          >
            {cargando ? 'Enviando...' : 'Enviar enlace'}
          </button>
          <a href="/login" className="block text-center text-slate-400 hover:underline text-sm">
            Volver al login
          </a>
        </form>
      </div>
    </div>
  );
}
```

**`pages/auth/ResetPasswordPage.tsx`:**
```tsx
import { useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import apiClient from '../../services/api';

export default function ResetPasswordPage() {
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [cargando, setCargando] = useState(false);
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const token = params.get('token') || '';

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setCargando(true);
    try {
      await apiClient.post('/auth/reset-password', { token, nuevaPassword: password });
      navigate('/login');
    } catch {
      setError('El enlace es inválido o expiró. Solicita uno nuevo.');
    } finally {
      setCargando(false);
    }
  };

  return (
    <div className="min-h-screen bg-surface flex items-center justify-center p-4">
      <div className="w-full max-w-md bg-surface-card rounded-2xl p-8">
        <h1 className="text-2xl font-bold text-white mb-2">Nueva contraseña</h1>
        <p className="text-slate-400 mb-8">Elige una contraseña de al menos 8 caracteres.</p>

        <form onSubmit={handleSubmit} className="space-y-5">
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full bg-surface border border-surface-border rounded-lg px-4 py-3 text-white focus:outline-none focus:border-primary-500"
            placeholder="Nueva contraseña"
            minLength={8}
            required
          />
          {error && <p className="text-red-400 text-sm">{error}</p>}
          <button
            type="submit"
            disabled={cargando}
            className="w-full bg-primary-500 hover:bg-primary-600 disabled:opacity-50 text-white font-semibold py-3 rounded-lg"
          >
            {cargando ? 'Guardando...' : 'Cambiar contraseña'}
          </button>
        </form>
      </div>
    </div>
  );
}
```

### Actualizar el router en `main.tsx`

Reemplazar el contenido de `main.tsx` para incluir todas las rutas de auth y las rutas protegidas:

```tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import './index.css';

import { useAuthStore } from './store/auth.store';
import { RutaProtegida } from './components/auth/RutaProtegida';

import LoginPage from './pages/auth/LoginPage';
import RegistroPage from './pages/auth/RegistroPage';
import RecuperarPasswordPage from './pages/auth/RecuperarPasswordPage';
import ResetPasswordPage from './pages/auth/ResetPasswordPage';
import Verificar2FAPage from './pages/auth/Verificar2FAPage';

import UsuarioPage from './pages/usuario';
import AdminPage from './pages/admin';
import GerentePage from './pages/gerente';

// Exponer el store para el interceptor de Axios
import { useAuthStore as authStoreInstance } from './store/auth.store';
(window as any).__authStore = { getState: () => authStoreInstance.getState() };

const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: 1, staleTime: 1000 * 60 * 5 } },
});

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Navigate to="/login" replace />} />

          {/* Rutas públicas */}
          <Route path="/login" element={<LoginPage />} />
          <Route path="/auth/registro" element={<RegistroPage />} />
          <Route path="/auth/recuperar-password" element={<RecuperarPasswordPage />} />
          <Route path="/auth/reset-password" element={<ResetPasswordPage />} />
          <Route path="/auth/2fa" element={<Verificar2FAPage />} />

          {/* Rutas protegidas por rol */}
          <Route
            path="/usuario/*"
            element={
              <RutaProtegida roles={['CLIENTE']}>
                <UsuarioPage />
              </RutaProtegida>
            }
          />
          <Route
            path="/admin/*"
            element={
              <RutaProtegida roles={['INSTRUCTOR']}>
                <AdminPage />
              </RutaProtegida>
            }
          />
          <Route
            path="/gerente/*"
            element={
              <RutaProtegida roles={['GERENTE']}>
                <GerentePage />
              </RutaProtegida>
            }
          />

          <Route
            path="*"
            element={
              <div className="min-h-screen bg-surface flex items-center justify-center">
                <p className="text-white">404 — Página no encontrada</p>
              </div>
            }
          />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  </React.StrictMode>,
);
```

### Checklist de verificación A1.4

Probar manualmente en el navegador:

- [ ] `http://localhost:5173/login` — la pantalla de login renderiza sin errores
- [ ] Login con credenciales correctas (usuario creado en A1.2) redirige a `/usuario`
- [ ] Login con credenciales incorrectas muestra el mensaje de error sin revelar cuál campo falla
- [ ] `http://localhost:5173/auth/registro` — el formulario de registro funciona y crea el usuario
- [ ] Después del registro, el usuario queda en el paso 2 (perfil físico) y puede ir al dashboard
- [ ] `http://localhost:5173/auth/recuperar-password` — el formulario envía y muestra el mensaje de confirmación
- [ ] Acceder a `/usuario` sin sesión redirige a `/login`
- [ ] Acceder a `/gerente` con token de CLIENTE redirige a `/login`
- [ ] Cerrar el navegador y volver a abrir `localhost:5173` — si había sesión activa, el usuario sigue autenticado (localStorage con refreshToken persiste)
- [ ] El botón de logout (agregar temporalmente en el placeholder de `/usuario`) limpia la sesión y redirige a `/login`

**Detente y reporta el checklist completo del G1 antes de dar el grupo por terminado.**

---

## Resultado esperado al finalizar G1

```
✅ Tablas usuarios, sesiones, recuperacion_passwords en PostgreSQL con todos los enums
✅ 7 endpoints de auth funcionando y verificados con curl/Postman
✅ Passwords siempre hasheados — nunca texto plano en BD
✅ Refresh tokens hasheados en BD — sesiones invalidables
✅ Guards JwtAuthGuard y RolesGuard reutilizables desde cualquier módulo
✅ Pantallas de login, registro, recuperación y 2FA funcionando en el navegador
✅ Rutas protegidas redirigen correctamente según rol
✅ Sesión persiste entre recargas del navegador
```

El Grupo 2 (Perfil de usuario y seguimiento físico) puede iniciarse una vez que todos los ítems anteriores estén confirmados.

---

*Smart Training · G1 para Claude Code · Junio 2026*
