import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsuariosModule } from './usuarios/usuarios.module';
import { EntrenamientoModule } from './entrenamiento/entrenamiento.module';
import { MaquinasModule } from './maquinas/maquinas.module';
import { GimnasioModule } from './gimnasio/gimnasio.module';
import { AdminModule } from './admin/admin.module';
import { FinanzasModule } from './finanzas/finanzas.module';
import { NotificacionesModule } from './notificaciones/notificaciones.module';
import { ReportesModule } from './reportes/reportes.module';
import { SchedulerModule } from './scheduler/scheduler.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    UsuariosModule,
    EntrenamientoModule,
    MaquinasModule,
    GimnasioModule,
    AdminModule,
    FinanzasModule,
    NotificacionesModule,
    ReportesModule,
    SchedulerModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
