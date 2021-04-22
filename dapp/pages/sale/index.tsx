// #region Global Imports
import * as React from "react";
import { NextPage } from "next";
// import { useSelector, useDispatch } from "react-redux";
// #endregion Global Imports

// #region Local Imports
import { withTranslation } from "@Server/i18n";
// import { IStore } from "@Redux/IStore";
import { HomeActions } from "@Actions";
import Header from "@Components/common/Header";
import SaleCard from "@Components/common/SaleCard";
// #endregion Local Imports

// #region Interface Imports
import { IHomePage, ReduxNextPageContext } from "@Interfaces";
// #endregion Interface Imports

import styles from "./index.module.scss";

const Sale: NextPage<IHomePage.IProps, IHomePage.InitialProps> = ({}) => {
  return (
    <div className={styles.wrapper}>
      <Header />
      <SaleCard />
    </div>
  );
};

Sale.getInitialProps = async (
  ctx: ReduxNextPageContext
): Promise<IHomePage.InitialProps> => {
  await ctx.store.dispatch(
    HomeActions.GetApod({
      params: { hd: true },
    })
  );
  return { namespacesRequired: ["common"] };
};

const Extended = withTranslation("common")(Sale);

export default Extended;
