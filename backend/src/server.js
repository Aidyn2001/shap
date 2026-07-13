// Shap backend — full API in one file (Express + Prisma + Socket.IO).
const http = require('http');
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');
const { Server } = require('socket.io');

const prisma = new PrismaClient();
const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 4000;
const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret_change_me';
const COMMISSION = parseFloat(process.env.PLATFORM_COMMISSION || '0.15');

// ---------- helpers ----------
const sign = (u) => jwt.sign({ id: u.id, role: u.role }, JWT_SECRET, { expiresIn: '7d' });
const safeUser = (u) => ({ id: u.id, fullName: u.fullName, email: u.email, phone: u.phone, role: u.role, rating: u.rating });
const wrap = (fn) => (req, res) => Promise.resolve(fn(req, res)).catch((e) => {
  console.error(e); res.status(500).json({ error: e.message || 'Server error' });
});
function auth(req, res, next) {
  const h = req.headers.authorization || '';
  const t = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!t) return res.status(401).json({ error: 'Missing auth token' });
  try { req.user = jwt.verify(t, JWT_SECRET); next(); }
  catch { return res.status(401).json({ error: 'Invalid or expired token' }); }
}
const allow = (...roles) => (req, res, next) =>
  req.user && roles.includes(req.user.role) ? next() : res.status(403).json({ error: 'Forbidden' });

// ---------- pricing ----------
const TIERS = {
  OLA: { base: 15, perKm: 6, perMin: 0.8, min: 25 },
  MOJO: { base: 30, perKm: 9.5, perMin: 1.2, min: 55 },
  GRAND: { base: 80, perKm: 16, perMin: 2.5, min: 150 },
};
const estimateFare = (tier, km, min) => {
  const t = TIERS[tier] || TIERS.OLA;
  return Math.round(Math.max(t.base + t.perKm * (km || 0) + t.perMin * (min || 0), t.min));
};
const splitCommission = (fare) => {
  const commission = Math.round(fare * COMMISSION);
  return { commission, driverEarnings: fare - commission };
};

// ---------- health ----------
app.get('/api/health', (req, res) => res.json({ status: 'ok', service: 'shap-api' }));

// ---------- auth ----------
app.post('/api/auth/register', wrap(async (req, res) => {
  const { fullName, email, phone, password, role } = req.body || {};
  if (!fullName || !email || !phone || !password) return res.status(400).json({ error: 'Missing fields' });
  const exists = await prisma.user.findFirst({ where: { OR: [{ email }, { phone }] } });
  if (exists) return res.status(409).json({ error: 'Email or phone already in use' });
  const passwordHash = await bcrypt.hash(password, 10);
  const user = await prisma.user.create({
    data: {
      fullName, email, phone, passwordHash,
      role: role === 'DRIVER' ? 'DRIVER' : 'PASSENGER',
      wallet: { create: {} },
      ...(role === 'DRIVER' ? { driverProfile: { create: {} } } : {}),
    },
  });
  res.status(201).json({ token: sign(user), user: safeUser(user) });
}));

app.post('/api/auth/login', wrap(async (req, res) => {
  const { email, password } = req.body || {};
  // Accept either email or phone typed into the login field.
  const user = await prisma.user.findFirst({ where: { OR: [{ email }, { phone: email }] } });
  if (!user) return res.status(401).json({ error: 'Invalid credentials' });
  const ok = await bcrypt.compare(password || '', user.passwordHash);
  if (!ok) return res.status(401).json({ error: 'Invalid credentials' });
  res.json({ token: sign(user), user: safeUser(user) });
}));

app.get('/api/auth/me', auth, wrap(async (req, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.user.id },
    include: { wallet: true, driverProfile: { include: { vehicle: true } } },
  });
  res.json({ user: safeUser(user), wallet: user.wallet, driverProfile: user.driverProfile });
}));

// ---------- rides ----------
app.post('/api/rides/quote', auth, wrap(async (req, res) => {
  const { tier, distanceKm, durationMin } = req.body || {};
  res.json({ tier, estimatedFare: estimateFare(tier, distanceKm, durationMin), currency: 'ZAR' });
}));

app.post('/api/rides', auth, wrap(async (req, res) => {
  const d = req.body || {};
  const estimatedFare = estimateFare(d.tier, d.distanceKm, d.durationMin);
  const ride = await prisma.ride.create({
    data: {
      tier: d.tier, status: d.tier === 'OLA' ? 'BIDDING' : 'REQUESTED',
      passengerId: req.user.id,
      pickupLat: d.pickupLat, pickupLng: d.pickupLng, pickupAddr: d.pickupAddr,
      dropLat: d.dropLat, dropLng: d.dropLng, dropAddr: d.dropAddr,
      distanceKm: d.distanceKm, durationMin: d.durationMin,
      suggestedFare: d.suggestedFare ?? null, estimatedFare,
      paymentMethod: d.paymentMethod || 'CASH', quietRide: !!d.quietRide,
      scheduledFor: d.scheduledFor ? new Date(d.scheduledFor) : null,
    },
  });
  res.status(201).json({ ride });
}));

app.get('/api/rides/mine', auth, wrap(async (req, res) => {
  const rides = await prisma.ride.findMany({ where: { passengerId: req.user.id }, orderBy: { createdAt: 'desc' }, take: 50 });
  res.json({ rides });
}));

app.get('/api/rides/:rideId/bids', auth, wrap(async (req, res) => {
  const bids = await prisma.bid.findMany({
    where: { rideId: req.params.rideId }, orderBy: { amount: 'asc' },
    include: { driver: { select: { fullName: true, rating: true } } },
  });
  res.json({ bids });
}));

app.get('/api/rides/:id', auth, wrap(async (req, res) => {
  const ride = await prisma.ride.findUnique({
    where: { id: req.params.id },
    include: { bids: true, driver: { include: { user: true, vehicle: true } }, payment: true },
  });
  if (!ride) return res.status(404).json({ error: 'Ride not found' });
  res.json({ ride });
}));

app.post('/api/rides/:id/complete', auth, wrap(async (req, res) => {
  const ride = await prisma.ride.findUnique({ where: { id: req.params.id } });
  if (!ride) return res.status(404).json({ error: 'Ride not found' });
  const finalFare = ride.finalFare ?? ride.estimatedFare;
  const { commission } = splitCommission(finalFare);
  const updated = await prisma.ride.update({ where: { id: ride.id }, data: { status: 'COMPLETED', finalFare, commission } });
  res.json({ ride: updated, ...splitCommission(finalFare) });
}));

// ---------- bids ----------
app.post('/api/bids/ride/:rideId', auth, allow('DRIVER'), wrap(async (req, res) => {
  const { amount } = req.body || {};
  const ride = await prisma.ride.findUnique({ where: { id: req.params.rideId } });
  if (!ride) return res.status(404).json({ error: 'Ride not found' });
  if (ride.tier !== 'OLA') return res.status(400).json({ error: 'Bidding only on Shap Ola' });
  const bid = await prisma.bid.create({ data: { rideId: ride.id, driverId: req.user.id, amount } });
  io.to('ride:' + ride.id).emit('bid:new', bid);
  res.status(201).json({ bid });
}));

app.post('/api/bids/:bidId/accept', auth, allow('PASSENGER'), wrap(async (req, res) => {
  const bid = await prisma.bid.findUnique({ where: { id: req.params.bidId }, include: { ride: true } });
  if (!bid) return res.status(404).json({ error: 'Bid not found' });
  if (bid.ride.passengerId !== req.user.id) return res.status(403).json({ error: 'Not your ride' });
  const dp = await prisma.driverProfile.findUnique({ where: { userId: bid.driverId } });
  const [ride] = await prisma.$transaction([
    prisma.ride.update({ where: { id: bid.rideId }, data: { status: 'ACCEPTED', driverId: dp && dp.id, finalFare: bid.amount } }),
    prisma.bid.update({ where: { id: bid.id }, data: { status: 'ACCEPTED' } }),
    prisma.bid.updateMany({ where: { rideId: bid.rideId, id: { not: bid.id } }, data: { status: 'REJECTED' } }),
  ]);
  io.to('ride:' + bid.rideId).emit('bid:accepted', { bidId: bid.id, ride });
  res.json({ ride });
}));

app.post('/api/bids/:bidId/reject', auth, allow('PASSENGER'), wrap(async (req, res) => {
  const bid = await prisma.bid.update({ where: { id: req.params.bidId }, data: { status: 'REJECTED' } });
  res.json({ bid });
}));

// ---------- drivers ----------
app.post('/api/drivers/online', auth, allow('DRIVER'), wrap(async (req, res) => {
  const p = await prisma.driverProfile.update({ where: { userId: req.user.id }, data: { isOnline: !!req.body.isOnline } });
  res.json({ driverProfile: p });
}));
app.post('/api/drivers/location', auth, allow('DRIVER'), wrap(async (req, res) => {
  const { lat, lng } = req.body || {};
  await prisma.driverProfile.update({ where: { userId: req.user.id }, data: { currentLat: lat, currentLng: lng } });
  res.json({ ok: true });
}));
app.get('/api/drivers/earnings', auth, allow('DRIVER'), wrap(async (req, res) => {
  const p = await prisma.driverProfile.findUnique({ where: { userId: req.user.id } });
  const rides = await prisma.ride.findMany({ where: { driverId: p && p.id, status: 'COMPLETED' } });
  const gross = rides.reduce((s, r) => s + (r.finalFare || 0), 0);
  const commission = rides.reduce((s, r) => s + (r.commission || 0), 0);
  res.json({ trips: rides.length, gross, commission, net: gross - commission, currency: 'ZAR' });
}));
app.post('/api/drivers/vehicle', auth, allow('DRIVER'), wrap(async (req, res) => {
  const d = req.body || {};
  const p = await prisma.driverProfile.findUnique({ where: { userId: req.user.id } });
  const data = { make: d.make, model: d.model, year: d.year, color: d.color, plate: d.plate, tier: d.tier || 'OLA' };
  const vehicle = await prisma.vehicle.upsert({ where: { driverId: p.id }, update: data, create: { driverId: p.id, ...data } });
  res.status(201).json({ vehicle });
}));

// ---------- payments (stub, ready for PayFast/Ozow/Yoco/Peach) ----------
app.post('/api/payments/initiate', auth, wrap(async (req, res) => {
  const { rideId, provider } = req.body || {};
  const ride = await prisma.ride.findUnique({ where: { id: rideId } });
  if (!ride) return res.status(404).json({ error: 'Ride not found' });
  const amount = ride.finalFare ?? ride.estimatedFare;
  const payment = await prisma.payment.upsert({
    where: { rideId }, update: { amount, provider, status: 'PENDING', method: ride.paymentMethod },
    create: { rideId, amount, provider, status: 'PENDING', method: ride.paymentMethod },
  });
  res.json({ payment, redirectUrl: 'https://sandbox.' + provider + '.example/checkout?ref=' + payment.id + '&amount=' + amount });
}));
app.post('/api/payments/webhook', wrap(async (req, res) => {
  const { reference, status } = req.body || {};
  if (!reference) return res.status(400).json({ error: 'Missing reference' });
  await prisma.payment.update({ where: { id: reference }, data: { status: status === 'success' ? 'PAID' : 'FAILED' } });
  res.json({ received: true });
}));

// ---------- admin ----------
app.get('/api/admin/stats', auth, allow('ADMIN'), wrap(async (req, res) => {
  const [users, drivers, rides, completed] = await Promise.all([
    prisma.user.count(), prisma.driverProfile.count(), prisma.ride.count(),
    prisma.ride.findMany({ where: { status: 'COMPLETED' } }),
  ]);
  res.json({ users, drivers, rides, completedRides: completed.length, platformRevenue: completed.reduce((s, r) => s + (r.commission || 0), 0) });
}));
app.get('/api/admin/verifications', auth, allow('ADMIN'), wrap(async (req, res) => {
  const drivers = await prisma.driverProfile.findMany({ where: { verification: 'PENDING' }, include: { user: { select: { fullName: true, email: true, phone: true } }, vehicle: true } });
  res.json({ drivers });
}));
app.post('/api/admin/drivers/:id/verify', auth, allow('ADMIN'), wrap(async (req, res) => {
  const p = await prisma.driverProfile.update({ where: { id: req.params.id }, data: { verification: req.body.decision } });
  res.json({ driverProfile: p });
}));
app.post('/api/admin/promos', auth, allow('ADMIN'), wrap(async (req, res) => {
  const d = req.body || {};
  const promo = await prisma.promo.create({ data: { code: d.code, description: d.description, discountPct: d.discountPct, discountFlat: d.discountFlat, maxUses: d.maxUses || 1000, expiresAt: d.expiresAt ? new Date(d.expiresAt) : null } });
  res.status(201).json({ promo });
}));
app.get('/api/admin/live-rides', auth, allow('ADMIN'), wrap(async (req, res) => {
  const rides = await prisma.ride.findMany({ where: { status: { in: ['ACCEPTED', 'DRIVER_ENROUTE', 'ARRIVED', 'IN_PROGRESS'] } }, include: { driver: { include: { user: { select: { fullName: true } } } } } });
  res.json({ rides });
}));

// ---------- server + real-time sockets ----------
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });
io.use((socket, next) => {
  try { socket.user = jwt.verify(socket.handshake.auth && socket.handshake.auth.token, JWT_SECRET); next(); }
  catch { next(new Error('unauthorized')); }
});
io.on('connection', (socket) => {
  const { id: userId, role } = socket.user;
  if (role === 'DRIVER') socket.join('drivers');
  if (role === 'ADMIN') socket.join('admins');
  socket.on('ride:join', (rideId) => socket.join('ride:' + rideId));
  socket.on('ride:leave', (rideId) => socket.leave('ride:' + rideId));
  socket.on('bid:message', async ({ bidId, body }) => {
    const msg = await prisma.bidMessage.create({ data: { bidId, senderId: userId, body } });
    const bid = await prisma.bid.findUnique({ where: { id: bidId } });
    io.to('ride:' + bid.rideId).emit('bid:message', msg);
  });
  socket.on('driver:location', async ({ rideId, lat, lng }) => {
    if (role !== 'DRIVER') return;
    await prisma.driverProfile.update({ where: { userId }, data: { currentLat: lat, currentLng: lng } }).catch(() => {});
    io.to('ride:' + rideId).emit('driver:location', { rideId, lat, lng });
  });
  socket.on('ride:status', ({ rideId, status }) => io.to('ride:' + rideId).emit('ride:status', { rideId, status }));
  socket.on('ride:sos', ({ rideId, lat, lng }) => io.to('admins').emit('ride:sos', { rideId, userId, lat, lng, at: Date.now() }));
});

// ---------- seed demo accounts on first boot ----------
async function seed() {
  const count = await prisma.user.count();
  if (count > 0) return;
  const hash = await bcrypt.hash('password123', 10);
  await prisma.user.create({ data: { fullName: 'Shap Admin', email: 'admin@shap.co.za', phone: '+27110000000', passwordHash: hash, role: 'ADMIN', wallet: { create: {} } } });
  await prisma.user.create({ data: { fullName: 'Thabo Mokoena', email: 'thabo@shap.co.za', phone: '+27110000001', passwordHash: hash, role: 'PASSENGER', wallet: { create: { balance: 200 } } } });
  await prisma.user.create({ data: { fullName: 'Lerato Dlamini', email: 'lerato@shap.co.za', phone: '+27110000002', passwordHash: hash, role: 'DRIVER', rating: 4.8, wallet: { create: {} }, driverProfile: { create: { isOnline: true, verification: 'APPROVED', currentLat: -26.2041, currentLng: 28.0473, vehicle: { create: { make: 'Toyota', model: 'Corolla Cross', year: 2023, color: 'White', plate: 'GP12345', tier: 'MOJO', verification: 'APPROVED' } } } } } });
  console.log('Seeded demo accounts (password: password123)');
}

server.listen(PORT, async () => {
  try { await seed(); } catch (e) { console.error('seed error', e); }
  console.log('Shap API listening on ' + PORT);
});
