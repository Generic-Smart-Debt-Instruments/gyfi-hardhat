import Button from "@Components/common/Button";
import React from "react";

import styles from "./index.module.scss";

const HomeContainer = () => {
  return (
    <div className={styles.container}>
      <table>
        <th colspan="2">{"Sale name"}</th>
        <tr>
          <td>Network:</td><td><Button variantClass={styles.button}>{"BSC"}</Button></td>
        </tr>
        <tr><td>Start Countdown</td><td>{"00:00:00"}</td></tr>
        <tr><td>End Countdown</td><td>{"00:00:00"}</td></tr>
        <tr>
          <td>Cap</td><td>{"1000"} {"BNB"}</td>
        </tr>
        <tr>
          <td>User Cap:</td><td>{"1000"} {"BNB"}</td>
        </tr>
        <tr><td>GYFI available:</td><td>{"1000"} GYFI</td></tr>
        <tr>
          <td>Rate:</td><td>{"1"} GYFI/{"BNB"}</td>
        </tr>
        <tr>
          <td>Contract Address:</td><td><a href={"#"}>{"0xABC"}</a></td>
        </tr>
      </table>
    </div>
  );
};

export default HomeContainer;
