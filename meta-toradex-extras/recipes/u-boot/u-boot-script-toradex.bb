############################################################################
##
## Copyright (C) 2016 The Qt Company Ltd.
## Contact: https://www.qt.io/licensing/
##
## This file is part of the Boot to Qt meta layer.
##
## $QT_BEGIN_LICENSE:GPL$
## Commercial License Usage
## Licensees holding valid commercial Qt licenses may use this file in
## accordance with the commercial license agreement provided with the
## Software or, alternatively, in accordance with the terms contained in
## a written agreement between you and The Qt Company. For licensing terms
## and conditions see https://www.qt.io/terms-conditions. For further
## information use the contact form at https://www.qt.io/contact-us.
##
## GNU General Public License Usage
## Alternatively, this file may be used under the terms of the GNU
## General Public License version 3 or (at your option) any later version
## approved by the KDE Free Qt Foundation. The licenses are as published by
## the Free Software Foundation and appearing in the file LICENSE.GPL3
## included in the packaging of this file. Please review the following
## information to ensure the GNU General Public License requirements will
## be met: https://www.gnu.org/licenses/gpl-3.0.html.
##
## $QT_END_LICENSE$
##
############################################################################

LICENSE = "The-Qt-Company-DCLA-2.1"
LIC_FILES_CHKSUM = "file://${QT_LICENSE};md5=80e06902b5f0e94ad0a78ee4f7fcb74b"
DEPENDS = "u-boot-mkimage-native"

PV = "v2.3"

SRC_URI = " \
    file://flash_mmc.scr \
    file://flash_blk.scr \
    "

S = "${WORKDIR}"

inherit deploy

do_mkimage () {
    uboot-mkimage -A arm -O linux -T script -C none -a 0 -e 0 \
                  -n "update script" -d ${WORKDIR}/flash_mmc.scr \
                  flash_mmc.img

    uboot-mkimage -A arm -O linux -T script -C none -a 0 -e 0 \
                  -n "update script" -d ${WORKDIR}/flash_blk.scr \
                  flash_blk.img
}

addtask mkimage after do_compile before do_install

do_deploy () {
    install -d ${DEPLOYDIR}
    install ${S}/flash_mmc.img ${DEPLOYDIR}/flash_mmc-${MACHINE}-${PV}-${PR}.img
    install ${S}/flash_blk.img ${DEPLOYDIR}/flash_blk-${MACHINE}-${PV}-${PR}.img

    cd ${DEPLOYDIR}
    rm -f flash_mmc-${MACHINE}.img
    ln -sf flash_mmc-${MACHINE}-${PV}-${PR}.img flash_mmc-${MACHINE}.img
    rm -f flash_blk-${MACHINE}.img
    ln -sf flash_blk-${MACHINE}-${PV}-${PR}.img flash_blk-${MACHINE}.img
}

addtask deploy after do_install before do_build

do_compile[noexec] = "1"
do_install[noexec] = "1"
do_populate_sysroot[noexec] = "1"

PACKAGE_ARCH = "${MACHINE_ARCH}"
COMPATIBLE_MACHINE = "(apalis-imx6|colibri-vf|colibri-imx6)"
