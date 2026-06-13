const { io } = require('socket.io-client');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const rider = await prisma.riderProfile.findFirst({ where: { isOnline: true }, include: { user: true } });
  if (!rider) { console.log('No online rider'); process.exit(0); }

  console.log(`Found online rider: ${rider.user.id}`);
  // In the real app, the backend verifies the JWT token.
  // We need a valid JWT token to join the rider room.
  console.log("Need a valid token for rider", rider.user.id);
  process.exit(0);
}
main();
