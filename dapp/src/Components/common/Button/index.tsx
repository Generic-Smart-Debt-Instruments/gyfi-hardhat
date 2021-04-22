import React, { FC, ReactNode } from "react";

import styles from "./index.module.scss";

interface IButton {
  type?: "button" | "submit";
  children: ReactNode;
  onClick?: () => void;
}

const Button: FC<IButton> = ({ type = "button", children, onClick }) => {
  return (
    <button type={type} onClick={onClick} className={styles.button}>
      {children}
    </button>
  );
};

export default Button;
