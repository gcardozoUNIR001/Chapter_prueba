import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import com.intuit.karate.junit5.Karate;
import org.junit.jupiter.api.Test;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import net.masterthought.cucumber.Configuration;
import net.masterthought.cucumber.ReportBuilder;

import static org.junit.jupiter.api.Assertions.assertTrue;

class KarateBasicTest {
    static {
        System.setProperty("karate.ssl", "true");
    }

    @Karate.Test
    Karate testBasic() {
        return Karate.run("classpath:karate-test.feature");
    }

    @Test
    public void testRunner() throws IOException {
        // Ejecuta las pruebas con tags si se especifican y desactiva las ejecuciones paralelas
        // para asegurar que los escenarios se ejecuten secuencialmente
        Results results = Runner.path("classpath:karate-test.feature")
                .tags("@MarvelAPI") // Tag principal que incluye todos los escenarios
                .outputCucumberJson(true)
                .parallel(1);

        // Ruta donde se generarán los reportes
        String karateOutputPath = "build/karate-reports";
        generateReport(karateOutputPath);

        // Muestra el resumen de resultados en la consola para ver todos los escenarios
        System.out.println("\n-------------------------------------------");
        System.out.println("RESUMEN DE PRUEBAS AUTOMATIZADAS MARVEL API");
        System.out.println("-------------------------------------------");
        System.out.println("Total de escenarios: " + results.getScenariosTotal());
        System.out.println("Escenarios pasados: " + results.getScenariosPassed());
        System.out.println("Escenarios fallidos: " + results.getScenariosFailed());

        // Lista los nombres de los escenarios ejecutados usando getFeature().getName() y scenario.getLine()
        System.out.println("\nESCENARIOS EJECUTADOS:");
        results.getScenarioResults().forEach(scenario -> {
            String status = scenario.isFailed() ? "✘ FALLIDO" : "✓ PASADO";
            String scenarioInfo = "Escenario en línea " + scenario.getScenario().getLine();
            System.out.println(" - " + scenarioInfo + ": " + status);
        });
        System.out.println("-------------------------------------------\n");

        // Verifica que no haya errores en la ejecución
        assertTrue(results.getFailCount() == 0, results.getErrorMessages());
    }

    // Método para generar reportes en formato Cucumber
    private static void generateReport(String karateOutputPath) {
        Collection<File> jsonFiles = filesByExtension(karateOutputPath, "json");
        List<String> jsonPaths = new ArrayList<>(jsonFiles.size());
        jsonFiles.forEach(file -> jsonPaths.add(file.getAbsolutePath()));

        Configuration config = new Configuration(new File("build"), "marvel-characters-api-tests");
        // Establecer el título del proyecto en el reporte
        config.addClassifications("Proyecto", "Marvel Characters API - Pruebas Automatizadas");
        config.addClassifications("Fecha", java.time.LocalDate.now().toString());
        config.addClassifications("Ambiente", "Test");
        config.addClassifications("Usuario", "gcardozo");

        ReportBuilder reportBuilder = new ReportBuilder(jsonPaths, config);
        reportBuilder.generateReports();

        System.out.println("Reportes generados en: " + new File("build/cucumber-html-reports").getAbsolutePath());
    }

    // Método para buscar archivos por extensión
    private static Collection<File> filesByExtension(String directoryPath, String extension) {
        File directory = new File(directoryPath);
        Collection<File> files = new ArrayList<>();

        if (directory.exists() && directory.isDirectory()) {
            for (File file : directory.listFiles()) {
                if (file.getName().endsWith("." + extension)) {
                    files.add(file);
                }
            }
        }

        return files;
    }
}
