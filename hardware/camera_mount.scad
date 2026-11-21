// 双目 IMX219 基线支架（参数化）
// 单位：mm。默认按 24x25mm IMX219( DC-IMX219-V1 )板、13x21mm 孔距、1.2mm 板厚设计。
// 摄像头由 4 个 Ø6.5 立柱架空 standoff_h；M2 螺丝从正面穿过 PCB 与立柱，
// 拧进立板背面的六角螺母（screw_mode=1，默认），螺母槽开在立板后面、PCB 装好后从背面塞入。
// 架空层给背面 FPC 座让位，排线从板底直接下垂，不穿板、不压线。
// 通孔是 Ø2.4 水平孔，顶部做了 45° 泪滴，避免 FDM 把孔顶拉塌成椭圆。
// 打印前务必用卡尺量你手头的板：孔距、孔径、FPC 座高度、镜头中心偏移。
// 基线 = 两个镜头中心距离，不是两块 PCB 边缘距离。

/* [Baseline] */
baseline = 80;          // 镜头中心距；推荐 80（近距操作/室内）

/* [Camera board] */
board_w = 24;           // 板宽 X
board_h = 25;           // 板高 Z（含 FPC 边）
board_t = 1.2;          // 板厚 Y
hole_dx = 13.25;        // 左右安装孔距（X）；实测 13.0 / 图纸 13.5，底孔做长圆孔兼容两者
hole_dy = 21;           // 上下安装孔距（Z）
standoff_h = 3.2;       // PCB 背面与立板的架空高度：必须 > FPC 座高度 + 0.8（座通常 2–2.5）
boss_d = 6.5;           // 立柱外径（M2 盘头约 3.8，留支撑面）
pilot_d = 1.9;          // M2 自攻底孔（仅 screw_mode=0；拧塑料 1.8–1.9）
pilot_into = 4.0;       // 自攻底孔深度（仅 screw_mode=0；立板 6，背面留 2.0）
pilot_slot = 1.2;       // 立板内长圆孔沿 X 的行程（±0.6），13.0–13.6 孔距都能装
screw_mode = 1;         // 1 = M2 机牙 + 背面六角螺母（默认）；0 = M2 自攻拧塑料
nut_af = 4.3;           // 六角螺母**对边**间隙：ISO 4032 M2 对边 4.0 + 0.3（不要填对角 4.6！）
nut_h = 1.9;            // 螺母槽深 = 螺母厚 1.6 + 0.3
nut_bridge = 1;         // 1 = 通孔顶部加 45° 泪滴，防止水平孔顶塌陷；0 = 纯圆孔（可钻）
lens_dx = 0;            // 镜头中心相对板中心的 X 偏移
lens_dz = 0;            // 镜头中心相对板中心的 Z 偏移

/* [Mount] */
plate_w = 34;           // 立板宽
plate_h = 38;           // 立板高
plate_t = 6;            // 立板厚：M2x10 刚好穿完 PCB+立柱+螺母；螺母槽后墙 4.05
base_t = 8;             // 底板厚（含 1/4-20 螺母槽）
base_depth = 38;        // 底板深
base_margin = 8;        // 底板两端余量
lens_z = 26;            // 镜头中心离底面高度
tripod_d = 6.4;         // 1/4-20 螺钉过孔
tripod_trap_d = 13;     // 1/4-20 六角螺母对角间隙（按你的螺母实测）
tripod_trap_h = 5.6;    // 螺母槽深；底板 8mm，留 2.4mm 顶

$fn = 32;

// 立板中心 = PCB 中心；镜头中心相对 PCB 中心偏移 lens_dx/lens_dz。
plate_spacing = baseline - 2 * lens_dx;
base_len = plate_spacing + plate_w + 2 * base_margin;
plate_z0 = base_t - 2;  // 与底板重叠 2mm，保证 union 后不脱开
plate_z1 = plate_z0 + plate_h;
board_cz = lens_z - lens_dz;
hole_y = standoff_h;    // 通孔起点：立柱顶面 == PCB 背面
nut_d = nut_af / cos(30);  // OpenSCAD 的 $fn=6 圆柱直径是**对角**，所以由对边换算
screw_clear_d = 2.4;    // M2 过孔（ISO 273 中等间隙），开在立板里
boss_bore_d = 2.8;      // 立柱内的圆孔：比过孔大 0.4，让螺钉歪一点也穿得过；PCB 面仍是完整支撑环
tee_apex = sqrt(2) * screw_clear_d / 2;  // 泪滴顶点离孔心高度：切线正好 45°

// 一颗螺丝的孔：默认机牙通孔 + 背面六角螺母槽（沿 X 做成 1.6mm 长圆孔，容忍 13.0–13.6 孔距）
module screw_hole(x, z) {
    if (screw_mode == 0) {
        hull() {
            for (o = [-pilot_slot / 2, pilot_slot / 2])
                translate([x + o, hole_y, z])
                    rotate([90, 0, 0])
                        cylinder(h = standoff_h + pilot_into, d = pilot_d);
        }
    } else {
        // 立柱内：Ø2.8 圆孔——PCB 面留完整的 Ø6.5 支撑环，螺钉头压板时板不会陷进长圆孔里
        translate([x, 0, z])
            rotate([-90, 0, 0])
                cylinder(h = standoff_h + 0.05, d = boss_bore_d);
        // 立板内：Ø2.4 长圆孔（只在立板里开，吃 13.0–13.6 孔距公差），顶部 45° 泪滴
        hull() {
            for (o = [-pilot_slot / 2, pilot_slot / 2])
                translate([x + o, -plate_t - 1, z])
                    rotate([-90, 0, 0])
                        cylinder(h = plate_t + 1.05, d = screw_clear_d);
            if (nut_bridge == 1)
                translate([x, -plate_t - 1, z + tee_apex - 0.005])
                    cube([0.01, plate_t + 1.05, 0.01]);
        }
        // 六角螺母槽：从立板背面挖，深 nut_h（$fn=6 → 平顶朝上，正好贴床方向）
        translate([x, -plate_t, z])
            rotate([-90, 0, 0])
                cylinder(h = nut_h + 0.05, d = nut_d, $fn = 6);
    }
}

module plate(cx) {
    difference() {
        union() {
            // 立板
            translate([cx - plate_w / 2, -plate_t, plate_z0])
                cube([plate_w, plate_t, plate_h]);

            // 四个镜头立柱：把 PCB 架离立板，给背面 FPC 座让位
            for (sx = [-1, 1], sz = [-1, 1])
                translate([cx + sx * hole_dx / 2, 0, board_cz + sz * hole_dy / 2])
                    rotate([-90, 0, 0])
                        cylinder(h = standoff_h, d = boss_d);
        }

        // 四颗 M2 螺丝孔：孔位就在立柱中心
        for (sx = [-1, 1], sz = [-1, 1])
            screw_hole(cx + sx * hole_dx / 2, board_cz + sz * hole_dy / 2);

    }
}

module gusset(cx, side) {
    // 三角筋：底板 -> 立板背面。放在两侧，给中间让路。
    gx = cx + side * (plate_w / 2 - 5);
    hull() {
        translate([gx - 2.5, -plate_t, plate_z0]) cube([5, plate_t, 1]);
        translate([gx - 2.5, -plate_t - 14, plate_z0]) cube([5, 1, 1]);
        translate([gx - 2.5, -plate_t, lens_z]) cube([5, 1, 1]);
    }
}

module body() {
    union() {
        // 底板
        translate([-base_len / 2, -base_depth + 8, 0])
            cube([base_len, base_depth, base_t]);

        // 两片立板
        plate(-plate_spacing / 2);
        plate( plate_spacing / 2);

        // 加强筋
        for (sx = [-1, 1]) {
            gusset(-plate_spacing / 2, sx);
            gusset( plate_spacing / 2, sx);
        }
    }
}

difference() {
    body();

    // 底板四角留安装孔（可选：扎带/螺丝固定到平台）
    for (sx = [-1, 1]) {
        translate([sx * (base_len / 2 - 6), 4, -0.1])
            cylinder(h = base_t + 0.2, d = 3.4, center = false);
    }

    // 1/4-20 三脚架：底部平贴床面，螺母从底部嵌入
    translate([0, 0, -0.1])
        cylinder(h = base_t + 0.2, d = tripod_d, center = false);
    translate([0, 0, -0.1])
        cylinder(h = tripod_trap_h, d = tripod_trap_d, center = false, $fn = 6);

    // 给三脚架螺钉头留一点底部沉孔
    translate([0, 0, -0.1])
        cylinder(h = 1.2, d = 12.0, center = false);
}

echo(str("baseline = ", baseline, " mm, plate spacing = ", plate_spacing, " mm"));
echo(str("PCB 架空 ", standoff_h, " mm，M2 ", screw_mode == 0 ? "自攻×8" : str("机牙×10 + 六角螺母×8（对边 ", nut_af, "，深 ", nut_h, "）"), "，孔距 ", hole_dx, "x", hole_dy));
// 打印方向：底板贴床，立板朝上；螺母槽开口朝后（-Y），不需要在腔里塞支撑。
// 支撑只加在两处：8 个立柱的圆柱下表面、底板中间 1/4-20 螺母槽的顶（≥5mm 跨度）。
// 材料：PETG 优于 PLA（抗蠕变、刚性更好）；不要用柔性材料。