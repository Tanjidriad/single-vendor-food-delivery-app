import { round2 } from './money.util';

describe('round2', () => {
  it('snaps floating-point drift back to the nearest paisa', () => {
    expect(round2(0.1 + 0.2)).toBe(0.3);
  });

  it('rounds half up', () => {
    expect(round2(1.005)).toBe(1.01);
    expect(round2(2.675)).toBe(2.68);
  });

  it('leaves clean amounts unchanged', () => {
    expect(round2(100)).toBe(100);
    expect(round2(49.99)).toBe(49.99);
  });

  it('handles zero and negative amounts', () => {
    expect(round2(0)).toBe(0);
    expect(round2(-1.005)).toBe(-1);
  });
});
