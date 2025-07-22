import { Controller, Get, Post, Body, Param, Query } from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from '../../dto/create-user.dto';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // Crear nuevo usuario
  @Post()
  async createUser(@Body() createUserDto: CreateUserDto) {
    try {
      const user = await this.usersService.createUser(createUserDto);
      return {
        success: true,
        user,
        timestamp: new Date()
      };
    } catch (error) {
      return {
        success: false,
        error: {
          message: error.message,
          code: 'USER_CREATION_ERROR'
        },
        timestamp: new Date()
      };
    }
  }

  // Obtener todos los usuarios
  @Get()
  async getAllUsers() {
    const users = await this.usersService.getAllUsers();
    return {
      users,
      count: users.length,
      timestamp: new Date()
    };
  }

  // Obtener usuario específico
  @Get(':userId')
  async getUser(@Param('userId') userId: string) {
    try {
      const user = await this.usersService.getUser(userId);
      return {
        user,
        timestamp: new Date()
      };
    } catch (error) {
      return {
        error: {
          message: error.message,
          code: 'USER_NOT_FOUND'
        },
        timestamp: new Date()
      };
    }
  }

  // Crear usuarios de prueba para roll-out gradual
  @Post('test/create')
  async createTestUsers(@Body() body: { count?: number }) {
    const count = body.count || 20;
    const users = await this.usersService.createTestUsers(count);
    
    return {
      success: true,
      message: `${users.length} usuarios de prueba creados`,
      users,
      timestamp: new Date()
    };
  }

  // Obtener estadísticas de usuarios
  @Get('stats/summary')
  async getUserStats() {
    const stats = await this.usersService.getUserStats();
    return {
      stats,
      timestamp: new Date()
    };
  }
} 