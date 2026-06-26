import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  healthCheck() {
    return {
      ok: true,
      service: 'Smart Training API',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
    };
  }
}
