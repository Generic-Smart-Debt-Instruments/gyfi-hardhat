import Button from "@Components/Button";
import { useEthers } from "@usedapp/core";
import React from "react";
import { CHAIN_LABELS } from "src/Constants";

import styles from "./index.module.scss";

const Header = () => {
  const { activateBrowserWallet, account, chainId } = useEthers();
  console.log(account);

  return (
    <div className={styles.header}>
      GYFI
      <section className={styles.actions}>
        {account ? (
          <div className={styles.info}>
            {chainId && (
              <span className={styles.network}>{CHAIN_LABELS[chainId]}</span>
            )}
            <span>{`Account: ${account}`}</span>
          </div>
        ) : (
          <Button onClick={() => activateBrowserWallet()}>
            Connect Wallet
          </Button>
        )}
      </section>
    </div>
  );
};

export default Header;
