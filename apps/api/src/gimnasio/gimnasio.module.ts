import { Module } from '@nestjs/common';
import { GimnasioController } from './gimnasio.controller';
import { GimnasioService } from './gimnasio.service';

@Module({
  controllers: [GimnasioController],
  providers: [GimnasioService],
  exports: [GimnasioService],
})
export class GimnasioModule {}
