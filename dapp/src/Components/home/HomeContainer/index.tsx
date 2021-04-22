import React from "react";
// import { useEthers } from "@usedapp/core";
// import { CHAIN_LABELS } from "@Constants";

// import styles from "./index.module.scss";

const HomeContainer = () => {
  return (
    <>
      <h2>Links</h2>
      <ul>
        <li>
          GYFI Token Sales:{" "}
          <a target="_blank" href="/sale">
            /sale
          </a>
        </li>
        <li>
          Whitepapers:{" "}
          <a target="_blank" href="https://whitepaper.gyfi.eth.link">
            whitepaper.gyfi.eth
          </a>
        </li>
        <li>
          Telegram Chat:{" "}
          <a target="_blank" href="https://t.me/GSDIofficial">
            t.me/GSDIofficial
          </a>
        </li>
        <li>
          Telegram Ann:{" "}
          <a target="_blank" href="https://t.me/GSDIAnnouncement">
            t.me/GSDIofficial
          </a>
        </li>
        <li>
          Twitter:{" "}
          <a target="_blank" href="https://twitter.com/GsdiOfficial">
            twitter.com/GsdiOfficial
          </a>
        </li>
        <li>
          Medium:{" "}
          <a target="_blank" href="https://gsdiofficial.medium.com/">
            gsdiofficial.medium.com
          </a>
        </li>
        <li>
          Discord:{" "}
          <a target="_blank" href="https://discord.gg/yG7SDGVGzP">
            discord.gg/yG7SDGVGzP
          </a>
        </li>
      </ul>
      <h2>About</h2>
      <p>
        <b>GSDI</b> - Generic Smart Debt Instruments are collateralized debt
        backed by smart wallets. Each GSDI is an ERC721 NFT with a unique
        borrower, price, face value, and maturity.
        <br />
        Article:{" "}
        <a href="https://gsdiofficial.medium.com/benefits-of-generic-smart-debt-instruments-901314a6fe5">
          Benefits of GSDI
        </a>
      </p>
      <p>
        <b>GYFI</b> - GSDI Yield Farming Token is the governance and protocol
        ERC20 token for the GSDI ecosystem. Rewards for ecosystem participants
        are issued in GYFI.
      </p>
      <p>
        <b>GAUC</b> - GSDI Auction is the first dapp to be build on GSDI. It
        allows the auction of proposed ERC20/721 collateralized bonds.
      </p>
      <p>
        <b>GSDI Pools</b> - GSDI Pools allow lenders to deposit Dai into
        strategies which purchase GSDI to earn interest. Any developer may
        deploy new pools and strategies.
      </p>
    </>
  );
};

export default HomeContainer;
