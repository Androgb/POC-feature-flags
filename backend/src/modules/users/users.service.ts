import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument } from '../../schemas/user.schema';
import { CreateUserDto } from '../../dto/create-user.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
  ) {}

  async createUser(createUserDto: CreateUserDto): Promise<User> {
    // Verificar si el usuario ya existe
    const existingUser = await this.userModel.findOne({ userId: createUserDto.userId });
    if (existingUser) {
      throw new BadRequestException('Usuario ya existe');
    }

    const user = new this.userModel(createUserDto);
    const savedUser = await user.save();
    
    console.log(`👤 Usuario creado: ${createUserDto.userId}`);
    return savedUser;
  }

  async getAllUsers(): Promise<User[]> {
    return this.userModel.find({ isActive: true }).sort({ createdAt: -1 });
  }

  async getUser(userId: string): Promise<User> {
    const user = await this.userModel.findOne({ userId, isActive: true });
    if (!user) {
      throw new BadRequestException('Usuario no encontrado');
    }
    return user;
  }

  async updateUser(userId: string, updates: Partial<User>): Promise<User> {
    const user = await this.userModel.findOneAndUpdate(
      { userId },
      { ...updates, updatedAt: new Date() },
      { new: true }
    );
    
    if (!user) {
      throw new BadRequestException('Usuario no encontrado');
    }
    
    return user;
  }

  // Método para generar usuarios de prueba (útil para testing roll-out gradual)
  async createTestUsers(count: number = 20): Promise<User[]> {
    const users = [];
    
    for (let i = 1; i <= count; i++) {
      const userId = `test_user_${i}`;
      const existingUser = await this.userModel.findOne({ userId });
      
      if (!existingUser) {
        const user = new this.userModel({
          userId,
          email: `test${i}@example.com`,
          name: `Test User ${i}`,
          role: 'user',
          metadata: {
            testUser: true,
            createdForRollout: true
          }
        });
        
        const savedUser = await user.save();
        users.push(savedUser);
      }
    }
    
    console.log(`👥 Creados ${users.length} usuarios de prueba para roll-out gradual`);
    return users;
  }

  // Obtener estadísticas de usuarios
  async getUserStats(): Promise<any> {
    const total = await this.userModel.countDocuments({ isActive: true });
    const testUsers = await this.userModel.countDocuments({ 
      isActive: true, 
      'metadata.testUser': true 
    });
    const realUsers = total - testUsers;
    
    return {
      total,
      testUsers,
      realUsers,
      timestamp: new Date()
    };
  }
} 