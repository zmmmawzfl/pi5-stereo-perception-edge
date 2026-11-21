// 双目 IMX219 基线支架（参数化）
// 单位：mm。默认按 24x25mm IMX219( DC-IMX219-V1 )板、13x21mm 孔距、1.2mm 板厚设计。
// 摄像头由 4 个 Ø6.5 立柱架空 standoff_h，M2 自攻螺丝从正面穿过 PCB 拧进立柱盲孔；
// 架空层给背面 FPC 座让位，排线从板底直接下垂，不穿板、不压线。
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
pilot_d = 1.9;          // M2 自攻底孔（拧塑料 1.8–1.9；用机牙+螺母请把 screw_mode 改成 1）
pilot_into = 4.0;       // 底孔拧进立板的深度（立板 7，背面留 3.0）
pilot_slot = 1.6;       // 底孔 X 向长圆孔行程，13.0–13.6 孔距都能装
screw_mode = 0;         // 0 = M2 自攻拧塑料；1 = M2 机牙 + 背面六角螺母
nut_d = 5.6;            // 六角螺母对角间隙（M2 螺母对边 4.0；按你实测改）
nut_h = 2.8;            // 螺母槽深（从立板背面挖）
lens_dx = 0;            // 镜头中心相对板中心的 X 偏移
lens_dz = 0;            // 镜头中心相对板中心的 Z 偏移

/* [Mount] */
plate_w = 34;           // 立板宽
plate_h = 38;           // 立板高
plate_t = 7;            // 立板厚（要给 M2 底孔留够 3mm 背墙）
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
hole_y = standoff_h;    // 螺纹孔的起点：立柱顶面 == PCB 背面

// 一颗螺丝的孔：默认 M2 自攻盲孔（沿 X 做成 1.6mm 长圆孔，容忍 13.0–13.6 孔距）
module screw_hole(x, z) {
    if (screw_mode == 0) {
        hull() {
            for (o = [-pilot_slot / 2, pilot_slot / 2])
                translate([x + o, hole_y, z])
                    rotate([90, 0, 0])
                        cylinder(h = standoff_h + pilot_into, d = pilot_d);
        }
    } else {
        // 机牙：Ø2.4 通孔 + 背面六角螺母槽
        hull() {
            for (o = [-pilot_slot / 2, pilot_slot / 2])
                translate([x + o, -plate_t - 1, z])
                    rotate([-90, 0, 0])
                        cylinder(h = standoff_h + plate_t + 2, d = 2.4);
        }
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
echo(str("PCB 架空 ", standoff_h, " mm，M2 ", screw_mode == 0 ? "自攻×8" : "机牙×10 + 螺母", "，孔距 ", hole_dx, "x", hole_dy));
// 打印方向：底板贴床，立板朝上；螺纹孔轴水平。建议 0.2mm 层高、4 圈壁、40% 填充；
// 螺纹孔附近用 6 圈壁并降速到 25mm/s，自攻牙才咬得住。
// 材料：PETG 优于 PLA（抗蠕变、刚性更好）；不要用柔性材料。