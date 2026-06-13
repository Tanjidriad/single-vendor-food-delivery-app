import {
  Controller,
  Get,
  Param,
  Patch,
  Query,
  UseGuards,
  Body,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags, ApiResponse } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { requireRestaurantId } from '../../common/utils/staff-restaurant.util';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { AdminService } from './admin.service';
import { PrismaService } from '../../prisma/prisma.service';
import {
  AdminOrderQueryDto,
  AdminUserQueryDto,
  PaginationDto,
  UpdateUserStatusDto,
  UpdateRiderApprovalDto,
  SuperAdminOrderQueryDto,
  SuperAdminRestaurantQueryDto,
} from './dto/admin.dto';

@ApiTags('admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.ADMIN)
@Controller('admin')
export class AdminController {
  constructor(
    private admin: AdminService,
    private prisma: PrismaService,
  ) {}

  @ApiOperation({ summary: 'Get dashboard KPI stats' })
  @ApiResponse({ status: 200, description: 'Dashboard metrics' })
  @Get('dashboard/stats')
  stats(@CurrentUser() user: JwtPayload) {
    return this.admin.getDashboardStats(requireRestaurantId(user));
  }

  // ─── Super Admin (Platform-wide) ──────────────────────────────────
  @ApiOperation({ summary: 'Get global dashboard KPI stats' })
  @Roles(UserRole.ADMIN)
  @Get('super/stats')
  globalStats() {
    return this.admin.getGlobalDashboardStats();
  }

  @ApiOperation({ summary: 'Get global daily revenue for charts' })
  @Roles(UserRole.ADMIN)
  @Get('super/revenue')
  globalRevenue(@Query('days') days?: string) {
    return this.admin.getGlobalDailyRevenue(days ? parseInt(days, 10) : 7);
  }

  @ApiOperation({ summary: 'List all platform orders with filters' })
  @Roles(UserRole.ADMIN)
  @Get('super/orders')
  globalOrders(@Query() query: SuperAdminOrderQueryDto) {
    return this.admin.listGlobalOrders(query);
  }

  @ApiOperation({ summary: 'Get single order detail globally' })
  @Roles(UserRole.ADMIN)
  @Get('super/orders/:id')
  globalOrderDetail(@Param('id') id: string) {
    return this.prisma.order.findUniqueOrThrow({
      where: { id },
      include: {
        items: true,
        restaurant: { select: { name: true, city: true } },
        customer: { select: { email: true, phone: true } },
        payment: true,
        assignment: { include: { rider: true } },
      },
    });
  }

  @ApiOperation({ summary: 'List all restaurants globally' })
  @Roles(UserRole.ADMIN)
  @Get('super/restaurants')
  globalRestaurants(@Query() query: SuperAdminRestaurantQueryDto) {
    return this.admin.listGlobalRestaurants(query);
  }

  @ApiOperation({ summary: 'Get single restaurant detail globally' })
  @Roles(UserRole.ADMIN)
  @Get('super/restaurants/:id')
  globalRestaurantDetail(@Param('id') id: string) {
    return this.prisma.restaurant.findUniqueOrThrow({
      where: { id },
      include: {
        _count: { select: { orders: true, staffProfiles: true, menuItems: true } },
      },
    });
  }
  // ──────────────────────────────────────────────────────────────────

  @ApiOperation({ summary: 'Get daily revenue for charts' })
  @Get('reports/daily-revenue')
  dailyRevenue(
    @CurrentUser() user: JwtPayload,
    @Query('days') days?: string,
  ) {
    return this.admin.getDailyRevenue(
      requireRestaurantId(user),
      days ? parseInt(days, 10) : 7,
    );
  }

  @ApiOperation({ summary: 'List orders with filters' })
  @Get('orders')
  orders(
    @CurrentUser() user: JwtPayload,
    @Query() query: AdminOrderQueryDto,
  ) {
    return this.admin.listOrders(requireRestaurantId(user), query);
  }

  @ApiOperation({ summary: 'List all users' })
  @Get('users')
  users(@Query() query: AdminUserQueryDto) {
    return this.admin.listUsers(query);
  }

  @ApiOperation({ summary: 'Get single user detail' })
  @Get('users/:id')
  async userDetail(@Param('id') id: string) {
    return this.prisma.user.findUniqueOrThrow({
      where: { id },
      select: {
        id: true,
        email: true,
        phone: true,
        role: true,
        status: true,
        createdAt: true,
        lastLoginAt: true,
        customerProfile: true,
        staffProfile: true,
        riderProfile: true,
        _count: { select: { orders: true, reviews: true } },
      },
    });
  }

  @ApiOperation({ summary: 'Suspend or activate user' })
  @Patch('users/:id/status')
  async updateUserStatus(
    @Param('id') id: string,
    @Body() dto: UpdateUserStatusDto,
  ) {
    return this.prisma.user.update({
      where: { id },
      data: { status: dto.status },
      select: { id: true, email: true, phone: true, role: true, status: true },
    });
  }

  @ApiOperation({ summary: 'List all riders' })
  @Get('riders')
  riders() {
    return this.admin.listRiders();
  }

  @ApiOperation({ summary: 'List pending riders waiting for approval' })
  @Get('riders/pending')
  pendingRiders() {
    return this.admin.listPendingRiders();
  }

  @ApiOperation({ summary: 'Approve or reject a rider' })
  @Patch('riders/:id/approve')
  approveRider(
    @Param('id') id: string,
    @Body() dto: UpdateRiderApprovalDto,
  ) {
    return this.admin.updateRiderApprovalStatus(id, dto.status);
  }

  @ApiOperation({ summary: 'List audit logs' })
  @Get('audit-logs')
  auditLogs(@Query() query: PaginationDto) {
    return this.admin.listAuditLogs(query.page ?? 1, query.limit ?? 20);
  }
}
