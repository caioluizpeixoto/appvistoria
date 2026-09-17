import { PixChargeResponse, PixProvider } from './PixProvider.ts';

export class MockPixProvider implements PixProvider {
  async initialize(): Promise<void> {
    // No initialization needed for mock
  }

  async createCharge(amount: number, companyId: string, rechargeId: string): Promise<PixChargeResponse> {
    const txid = `MOCKTXID${Date.now()}${Math.floor(Math.random() * 1000)}`;
    const pixCopyPaste = `00020101021226580014br.gov.bcb.pix0136mock-pix-key-for-testing5204000053039865405${amount.toFixed(2)}5802BR5915MOCK PAYEE NAME6008BRASILIA62170513${txid}63041234`;
    
    return {
      txid,
      pixCopyPaste,
      qrCodeData: pixCopyPaste, // In a real scenario, this might be a direct copy-paste string which serves as QR content
    };
  }
}
