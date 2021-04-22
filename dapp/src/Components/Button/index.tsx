import React, { FC, ReactNode } from "react";

import styles from "./index.module.scss";

interface IButton {
    children: ReactNode;
}

const Button: FC<IButton> = ({ children, ...otherProps }) => {
    return (
        <button {...otherProps} className={styles.button}>
            {children}
        </button>
    );
};

export default Button;
