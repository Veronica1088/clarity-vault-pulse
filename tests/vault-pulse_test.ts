import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can create new vault",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "vault-pulse",
        "create-vault",
        [types.ascii("My First Vault")],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    block.receipts[0].result
      .expectOk()
      .expectUint(1);
  },
});

Clarinet.test({
  name: "Ensure can add asset to vault",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "vault-pulse",
        "create-vault",
        [types.ascii("My First Vault")],
        wallet_1.address
      ),
      Tx.contractCall(
        "vault-pulse",
        "add-asset",
        [types.uint(1), types.ascii("Gold"), types.uint(100)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 2);
    block.receipts[1].result
      .expectOk()
      .expectUint(1);
  },
});
