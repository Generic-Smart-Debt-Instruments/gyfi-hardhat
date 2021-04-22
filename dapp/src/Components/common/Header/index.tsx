import React from "react";
import { useEthers } from "@usedapp/core";

import Button from "@Components/common/Button";
import { CHAIN_LABELS } from "@Constants";

import styles from "./index.module.scss";

const Header = () => {
  const { activateBrowserWallet, account, chainId } = useEthers();

  return (
    <div className={styles.header}>
      <a href="/">GYFI</a>
      <section className={styles.actions}>
        {account ? (
          <div className={styles.info}>
            {chainId && (
              <span className={styles.network}>{CHAIN_LABELS[chainId]}</span>
            )}
            <span className={styles.account}>{`${account}`}</span>
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
