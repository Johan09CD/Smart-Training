import { Module } from '@nestjs/common';
import { EntrenamientoController } from './entrenamiento.controller';
import { EntrenamientoService } from './entrenamiento.service';

@Module({
  controllers: [EntrenamientoController],
  providers: [EntrenamientoService],
  exports: [EntrenamientoService],
})
export class EntrenamientoModule {}
