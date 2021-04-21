import Button from "@Components/common/Button";
import React from "react";

import styles from "./index.module.scss";

const HomeContainer = () => {
  return (
    <div className={styles.container}>
      <h3>Next Sale</h3>
      <ul>
        <li>
          Network: <Button variantClass={styles.button}>{"BSC"}</Button>
        </li>
        <li>Start Countdown: {"00:00:00"}</li>
        <li>End Countdown: {"00:00:00"}</li>
        <li>
          Cap: {"1000"} {"BNB"}
        </li>
        <li>
          User Cap: {"1000"} {"BNB"}
        </li>
        <li>GYFI available: {"1000"} GYFI</li>
        <li>
          Rate: {"1"} GYFI/{"BNB"}
        </li>
        <li>
          Contract Address: <a href={"#"}>{"0xABC"}</a>
        </li>
      </ul>
    </div>
  );
};

export default HomeContainer;
