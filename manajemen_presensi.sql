package com.rplbo.app.demo;

import javafx.animation.Animation;
import javafx.animation.KeyFrame;
import javafx.animation.Timeline;
import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.scene.Node;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.Label;
import javafx.stage.Stage;
import javafx.util.Duration;

import java.io.IOException;
import java.net.URL;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import java.util.ResourceBundle;

public class DashboardController implements Initializable {

    // LABEL DASHBOARD
    @FXML private Label lblJam;
    @FXML private Label lblTanggal;
    @FXML private Label lblNamaProfil;
    @FXML private Label lblStatusDetail;
    @FXML private Label lblHadir;
    @FXML private Label lblTerlambat;
    @FXML private Label lblCuti;
    @FXML private Label lblIzin;

// Menghubungkan dashboard dengan akun Ria (id_karyawan = 3)
    private final int ID_KARYAWAN_LOGIN = 3;

    @Override
public void initialize(URL location, ResourceBundle resources) {
        initClock();

// Memuat status & rekap langsung dari Database
        loadUserData();
}

    /**
     * JAM DIGITAL REALTIME
     */
    private void initClock() {
        Locale localeID = new Locale("id", "ID");
        DateTimeFormatter timeFormatter = DateTimeFormatter.ofPattern("HH:mm:ss");
        DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("EEEE, dd MMMM yyyy", localeID);

        Timeline clock = new Timeline(
                new KeyFrame(Duration.ZERO, e -> {
                    LocalDateTime now = LocalDateTime.now();
                    lblJam.setText(now.format(timeFormatter));
                    lblTanggal.setText(now.format(dateFormatter));
                }),
                new KeyFrame(Duration.seconds(1))
        );

        clock.setCycleCount(Animation.INDEFINITE);
        clock.play();
}

    /**
     * LOAD DATA DASHBOARD DARI DATABASE
     */
    private void loadUserData() {
        try (Connection conn = DatabaseConnection.getConnection()) {
            LocalDate hariIni = LocalDate.now();

// 1. CEK STATUS PRESENSI HARI INI
            String sqlStatus = "SELECT jam_masuk, jam_keluar FROM tb_presensi WHERE tanggal = ? AND id_karyawan = ?";
            PreparedStatement pstStatus = conn.prepareStatement(sqlStatus);
            pstStatus.setDate(1, java.sql.Date.valueOf(hariIni));
            pstStatus.setInt(2, ID_KARYAWAN_LOGIN);

            ResultSet rsStatus = pstStatus.executeQuery();

            if (rsStatus.next()) {
                // Jika sudah ada jam keluar
                if (rsStatus.getString("jam_keluar") != null) {
                    lblStatusDetail.setText("✅ Presensi Selesai. Selamat Beristirahat.");
                    lblStatusDetail.setStyle("-fx-text-fill: #27C93F; -fx-font-weight: bold;"); // Hijau
                } else {
                    // Jika baru jam masuk (Clock-In)
                    lblStatusDetail.setText("⏳ Sudah Clock-In. Jangan lupa Clock-Out nanti.");
                    lblStatusDetail.setStyle("-fx-text-fill: #1976D2; -fx-font-weight: bold;"); // Biru
                }
            } else {
                // Jika tidak ada data absensi sama sekali hari ini
                lblStatusDetail.setText("Belum Absen Hari Ini. Silakan Clock-In.");
                lblStatusDetail.setStyle("-fx-text-fill: #D32F2F; -fx-font-weight: bold;"); // Merah
            }
            rsStatus.close();
            pstStatus.close();

// 2. HITUNG TOTAL HADIR BULAN INI
            String sqlHadir = "SELECT COUNT(*) as total FROM tb_presensi WHERE id_karyawan = ? AND MONTH(tanggal) = MONTH(CURRENT_DATE()) AND YEAR(tanggal) = YEAR(CURRENT_DATE()) AND status_kehadiran = 'hadir'";
            PreparedStatement pstHadir = conn.prepareStatement(sqlHadir);
            pstHadir.setInt(1, ID_KARYAWAN_LOGIN);
            ResultSet rsHadir = pstHadir.executeQuery();
            if (rsHadir.next()) lblHadir.setText(rsHadir.getString("total") + " hari");
            rsHadir.close(); pstHadir.close();

// 3. HITUNG TOTAL TERLAMBAT BULAN INI
            String sqlTerlambat = "SELECT COUNT(*) as total FROM tb_presensi WHERE id_karyawan = ? AND MONTH(tanggal) = MONTH(CURRENT_DATE()) AND YEAR(tanggal) = YEAR(CURRENT_DATE()) AND status_waktu = 'terlambat'";
            PreparedStatement pstTerlambat = conn.prepareStatement(sqlTerlambat);
            pstTerlambat.setInt(1, ID_KARYAWAN_LOGIN);
            ResultSet rsTerlambat = pstTerlambat.executeQuery();
            if (rsTerlambat.next()) lblTerlambat.setText(rsTerlambat.getString("total") + " kali");
            rsTerlambat.close(); pstTerlambat.close();

// 4. HITUNG TOTAL CUTI DISETUJUI
            String sqlCuti = "SELECT COUNT(*) as total FROM tb_izin_cuti WHERE id_karyawan = ? AND jenis_izin = 'cuti' AND status_persetujuan = 'disetujui'";
            PreparedStatement pstCuti = conn.prepareStatement(sqlCuti);
            pstCuti.setInt(1, ID_KARYAWAN_LOGIN);
            ResultSet rsCuti = pstCuti.executeQuery();
            if (rsCuti.next()) lblCuti.setText(rsCuti.getString("total") + " hari");
            rsCuti.close(); pstCuti.close();

// 5. HITUNG TOTAL IZIN/SAKIT DISETUJUI
            String sqlIzin = "SELECT COUNT(*) as total FROM tb_izin_cuti WHERE id_karyawan = ? AND jenis_izin IN ('sakit', 'kepentingan lain') AND status_persetujuan = 'disetujui'";
            PreparedStatement pstIzin = conn.prepareStatement(sqlIzin);
            pstIzin.setInt(1, ID_KARYAWAN_LOGIN);
            ResultSet rsIzin = pstIzin.executeQuery();
            if (rsIzin.next()) lblIzin.setText(rsIzin.getString("total") + " hari");
            rsIzin.close(); pstIzin.close();

} catch (Exception e) {
            System.err.println("Gagal memuat data dari database!");
            e.printStackTrace();
}
    }

    public void setNamaPengguna(String username) {
        lblNamaProfil.setText(username);
}

    // =====================================================
    // NAVIGASI MENU
    // =====================================================

    @FXML
    private void handleMenuBeranda(ActionEvent event) {
        System.out.println("Anda sedang berada di Dashboard.");
}

    @FXML
    private void handleMenuPresensi(ActionEvent event) {
        pindahHalaman(event, "presensi-view.fxml", "Manajemen Presensi - Presensi");
}

    @FXML
    private void handleMenuRiwayat(ActionEvent event) {
        pindahHalaman(event, "riwayat-view.fxml", "Manajemen Presensi - Riwayat");
}

    @FXML
    private void handleMenuCuti(ActionEvent event) {
        pindahHalaman(event, "cuti-view.fxml", "Manajemen Presensi - Cuti");
}

    @FXML
    private void handleLogout(ActionEvent event) {
        try {
            FXMLLoader loader = new FXMLLoader(getClass().getResource("login-view.fxml"));
            Parent root = loader.load();
            Stage stage = (Stage)((Node)event.getSource()).getScene().getWindow();
            stage.setScene(new Scene(root, 400, 500));
            stage.setTitle("Manajemen Presensi - Login");
            stage.centerOnScreen();
            stage.show();
} catch (IOException e) {
            System.err.println("Gagal logout");
            e.printStackTrace();
}
    }

    /**
     * Helper Method untuk pindah halaman
     */
    private void pindahHalaman(ActionEvent event, String fxmlFile, String title) {
        try {
            FXMLLoader loader = new FXMLLoader(getClass().getResource(fxmlFile));
            Parent root = loader.load();
            Stage stage = (Stage)((Node)event.getSource()).getScene().getWindow();
            stage.setScene(new Scene(root, 900, 600));
            stage.setTitle(title);
            stage.show();
} catch (IOException e) {
            System.err.println("Gagal membuka halaman: " + fxmlFile);
            e.printStackTrace();
}
    }
}