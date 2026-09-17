export interface PixChargeResponse {
  txid: string;
  pixCopyPaste: string;
  qrCodeData: string;
}

export interface PixProvider {
  /**
   * Inicializa ou valida as credenciais. Lança erro se não estiver configurado corretamente.
   */
  initialize(): Promise<void>;

  /**
   * Cria uma cobrança Pix no provedor
   * @param amount Valor da cobrança
   * @param companyId ID da empresa no sistema
   * @param rechargeId ID interno da recarga
   * @returns txid, copia e cola e qr code
   */
  createCharge(amount: number, companyId: string, rechargeId: string): Promise<PixChargeResponse>;
}
