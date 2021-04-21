// #region Global Imports
import * as React from "react";
import App, { AppInitialProps, AppContext } from "next/app";
import { Provider } from "react-redux";
import { ThemeProvider } from "styled-components";
import withRedux from "next-redux-wrapper";
import { DAppProvider, Config } from "@usedapp/core";
// #endregion Global Imports

// #region Local Imports
import { theme } from "@Definitions/Styled";
import { appWithTranslation } from "@Server/i18n";
import { AppWithStore } from "@Interfaces";
import { makeStore } from "@Redux";
import {
  CHAINS,
  MUTICALL_ADDRESSES,
  RPC_URLS,
  SUPPORT_CHAINS,
} from "src/Constants";

import "@Static/css/main.scss";
// #endregion Local Imports

const config: Config = {
  readOnlyChainId: CHAINS.Rinkeby,
  readOnlyUrls: RPC_URLS,
  supportedChains: SUPPORT_CHAINS,
  multicallAddresses: MUTICALL_ADDRESSES,
};

class WebApp extends App<AppWithStore> {
  static async getInitialProps({
    Component,
    ctx,
  }: AppContext): Promise<AppInitialProps> {
    const pageProps = Component.getInitialProps
      ? await Component.getInitialProps(ctx)
      : {};

    return { pageProps };
  }

  render() {
    const { Component, pageProps, store } = this.props;

    return (
      <Provider store={store}>
        <DAppProvider config={config}>
          <ThemeProvider theme={theme}>
            <Component {...pageProps} />
          </ThemeProvider>
        </DAppProvider>
      </Provider>
    );
  }
}

export default withRedux(makeStore)(appWithTranslation(WebApp));
