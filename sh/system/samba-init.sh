#!/bin/bash

systemctl daemon-reload
systemctl enable smbd
systemctl enable nmbd
systemctl start smbd
systemctl start nmbd

exit 0

