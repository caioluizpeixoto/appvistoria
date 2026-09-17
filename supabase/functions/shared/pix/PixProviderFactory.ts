import { PixProvider } from './PixProvider.ts';
import { SicrediPixProvider } from './SicrediPixProvider.ts';
import { MockPixProvider } from './MockPixProvider.ts';

export function getPixProvider(): PixProvider {
  const mode = Deno.env.get('PIX_PROVIDER_MODE') || 'mock';
  
  if (mode.toLowerCase() === 'sicredi') {
    return new SicrediPixProvider();
  }
  
  return new MockPixProvider();
}
