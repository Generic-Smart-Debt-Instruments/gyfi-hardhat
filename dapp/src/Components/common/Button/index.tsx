import React, { FC, ReactNode } from "react";
import BaseButton, { ButtonProps } from "@material-ui/core/Button";

import styles from "./index.module.scss";

interface IButton extends Partial<ButtonProps> {
  children: ReactNode;
  variantClass?: string;
}

const Button: FC<IButton> = ({ children, variantClass, ...otherProps }) => {
  return (
    <BaseButton {...otherProps} className={`${styles.button} ${variantClass}`}>
      {children}
    </BaseButton>
  );
};

export default Button;
