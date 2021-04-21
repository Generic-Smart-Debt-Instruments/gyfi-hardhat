import React, { FC, ReactNode } from "react";
import BaseButton, { ButtonProps } from "@material-ui/core/Button";

import styles from "./index.module.scss";

interface IButton extends Partial<ButtonProps> {
    children: ReactNode;
}

const Button: FC<IButton> = ({ children, ...otherProps }) => {
    return (
        <BaseButton {...otherProps} className={styles.button}>
            {children}
        </BaseButton>
    );
};

export default Button;
