(use-modules (gnu) (gnu system nss) (guix utils)
             (guix packages) (gnu packages linux)
             (gnu packages freedesktop) (gnu packages fcitx5)
             (gnu packages fonts) (gnu packages wm)
             (gnu packages xdisorg) (gnu packages lxqt)
             (nongnu packages linux)
             (nongnu system linux-initrd) (gnu packages wget) (gnu packages curl) (gnu packages certs))
(use-service-modules desktop networking)

(define my-keyboard-layout (keyboard-layout "us"))

(define crypted-root
  (mapped-device
   (source (uuid "3271b399-e5bf-43bc-96e3-096ebde47396"))
   (target "crypted")
   (type luks-device-mapping)))

(operating-system
  (kernel linux)                                  ; linux-libre -> 공식 linux 커널
  (kernel-arguments (cons "modprobe.blacklist=pcspkr" %default-kernel-arguments))
  (initrd microcode-initrd)                       ; CPU 마이크로코드 초기 적용
  (firmware (list linux-firmware))                ; 비자유 펌웨어(무선랜 등) 허용
  (initrd-modules (cons "vmd" %base-initrd-modules))
  (host-name "guix")
  (timezone "Asia/Seoul")
  (locale "ko_KR.utf8")

  (keyboard-layout my-keyboard-layout)

  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets '("/boot/efi"))
                (keyboard-layout my-keyboard-layout)))

  (mapped-devices (list crypted-root))

  (file-systems (append
                 (list (file-system
                         (device "/dev/mapper/crypted")
                         (mount-point "/")
                         (type "btrfs")
                         (options "subvol=@guix")
                         (dependencies (list crypted-root)))

                       (file-system
                        (mount-point "/home")
                        (device "/dev/mapper/crypted")
                        (type "btrfs")
                        (options "subvol=@ghome")
                        (dependencies (list crypted-root)))

                       (file-system
                        (mount-point "/boot/efi")
                        (device (uuid "c121-3362" 'fat))
                        (type "vfat")))
                 %base-file-systems))

  (users (cons (user-account
                (name "l")
                (comment "Alice's brother")
                (password (crypt " " "6abc"))
                (group "students")
                (supplementary-groups '("wheel" "netdev"
                                        "audio" "video")))
               %base-user-accounts))

  (groups (cons* (user-group
                  (name "students"))
                 %base-groups))

  (packages (append (list
                      ;; sway 핵심
                      sway
                      foot
                      waybar
                      swaybg
                      swaylock
                      swayidle
                      ;; wofi
                      grim
                      slurp
                      wl-clipboard
                      mako
                      ;; brightnessctl 밝기 조절
                      mate-polkit
                      font-google-noto-sans-cjk                      
                      xdg-desktop-portal-wlr
                      pipewire
                      wireplumber
                      pavucontrol
                      fcitx5
                      fcitx5-configtool
                      fcitx5-gtk
                      fcitx5-qt
                      wget
					  curl
					  nss-certs
					  icecat)
                    %base-packages))

  (services
   (append
    (list
     (simple-service 'wayland-fcitx5-env
                      session-environment-service-type
                      '(("GTK_IM_MODULE" . "fcitx")
                        ("QT_IM_MODULE" . "fcitx")
                        ("XMODIFIERS" . "@im=fcitx")
                        ("INPUT_METHOD" . "fcitx")))
     (service bluetooth-service-type))
    ;; %base-services -> %desktop-services 로 교체
    ;; (NetworkManager, wpa-supplicant, polkit, elogind, dbus,
    ;;  upower, udisks, avahi 등이 여기 다 포함돼 있음)
    %desktop-services))

  (name-service-switch %mdns-host-lookup-nss))
