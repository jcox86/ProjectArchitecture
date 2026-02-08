/*
module: src.adminUi.naive
purpose: Register commonly used Naive UI components globally.
exports:
  - naive: plugin
patterns:
  - naive_ui
*/
import {
  NAlert,
  NButton,
  NCard,
  NConfigProvider,
  NDataTable,
  NDialogProvider,
  NForm,
  NFormItem,
  NGi,
  NGrid,
  NInput,
  NLayout,
  NLayoutContent,
  NLayoutHeader,
  NLayoutSider,
  NMenu,
  NMessageProvider,
  NNotificationProvider,
  NSelect,
  NSpace,
  NSpin,
  NTag,
  NText,
  create
} from "naive-ui";

export const naive = create({
  components: [
    NAlert,
    NButton,
    NCard,
    NConfigProvider,
    NDataTable,
    NDialogProvider,
    NForm,
    NFormItem,
    NGi,
    NGrid,
    NInput,
    NLayout,
    NLayoutContent,
    NLayoutHeader,
    NLayoutSider,
    NMenu,
    NMessageProvider,
    NNotificationProvider,
    NSelect,
    NSpace,
    NSpin,
    NTag,
    NText
  ]
});
