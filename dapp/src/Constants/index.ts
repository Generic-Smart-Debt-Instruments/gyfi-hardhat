import { ChainId } from "@usedapp/core";

export const CHAINS = {
    ...ChainId,
    BSC: 56,
    BSCTestnet: 97,
};

export const CHAIN_RPC_URLS = {
    [CHAINS.Mainnet]: `https://mainnet.infura.io/v3/${process.env.NEXT_PUBLIC_INFURA}`,
    [CHAINS.Ropsten]: `https://ropsten.infura.io/v3/${process.env.NEXT_PUBLIC_INFURA}`,
};
