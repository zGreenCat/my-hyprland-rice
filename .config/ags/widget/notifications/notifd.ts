import AstalNotifd from "gi://AstalNotifd?version=0.1"

export const notifd = AstalNotifd.get_default()
export type Notification = AstalNotifd.Notification
