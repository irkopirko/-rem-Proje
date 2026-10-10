import 'dotenv/config';
import 'express-async-errors';
import http from 'http';
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import authRoutes from './routes/auth.js';
import studentRoutes from './routes/student.js';
import crewRoutes from './routes/crew.js';
import crewLearningRoutes from './routes/crewLearning.js';
import adminRoutes from './routes/admin.js';
import communityRoutes from './routes/community.js';
import mediaRoutes from './routes/media.js';
import webhookRoutes from './routes/webhooks.js';
import { ensureSuperAdmin, ensureCrewPortal } from './services/bootstrap.js';
import { attachCommunitySocket } from './services/community.js';
import { MailDeliveryError } from './services/mail.js';
import { runMigrations } from './migrate.js';

const app = express();
// Railway terminates TLS at a single proxy hop; needed for correct req.ip and rate limiting.
app.set('trust proxy', 1);

app.use(helmet());
app.use(compression());
app.use(express.json({ limit: '1mb' }));

const origins = (process.env.CORS_ORIGINS || '*').split(',').map((s) => s.trim());
app.use(
  cors({
    origin: origins.includes('*') ? true : origins,
    credentials: true,
  })
);

const limiter = (windowMs, max) => rateLimit({ windowMs, max, standardHeaders: true, legacyHeaders: false });

// Credential endpoints get a much tighter budget than the rest of /auth.
app.use(['/auth/login', '/auth/register', '/auth/password/forgot', '/auth/password/reset'], limiter(15 * 60 * 1000, 30));
app.use('/auth', limiter(15 * 60 * 1000, 300), authRoutes);

app.get('/health', (_req, res) => res.json({ ok: true, service: 'ink-akademi-api' }));

// Mail clients embed these images from other origins.
app.use(
  '/static',
  (_req, res, next) => {
    res.set('Cross-Origin-Resource-Policy', 'cross-origin');
    next();
  },
  express.static(new URL('../public', import.meta.url).pathname, { maxAge: '7d', index: false })
);

app.use('/webhooks', limiter(60 * 1000, 600), webhookRoutes);
app.use('/media', limiter(60 * 1000, 1200), mediaRoutes);
app.use('/v1', limiter(60 * 1000, 1200));
app.use('/v1/community', communityRoutes);
app.use('/v1/crew', crewLearningRoutes);
app.use('/v1/crew', crewRoutes);
app.use('/v1/admin', adminRoutes);
app.use('/v1', studentRoutes);

app.use((err, _req, res, _next) => {
  if (err?.type === 'entity.too.large') return res.status(413).json({ error: 'Payload too large' });
  if (err instanceof MailDeliveryError) return res.status(503).json({ error: 'Mail delivery failed' });
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

const port = Number(process.env.PORT || 8080);
const server = http.createServer(app);
attachCommunitySocket(server);

runMigrations()
  .then(() => ensureSuperAdmin())
  .then(() => ensureCrewPortal())
  .then(() => {
    server.listen(port, () => console.log(`Ink Akademi API listening on ${port}`));
  })
  .catch((err) => {
    console.error('Bootstrap failed', err);
    process.exit(1);
  });
