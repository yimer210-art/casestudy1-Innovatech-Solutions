# Innovatech Solutions - SOAR (Security Orchestration, Automation and Response)
## Case Study 2 - Flavor B: Advanced Automation

Deze map bevat alle Infrastructure-as-Code (IaC) en workflowdefinities voor het geautomatiseerde SOAR incident response platform van Innovatech Solutions.

---

### Bestanden in deze map:

1. **`shuffle-workflow-mitigation.json`**
   - De volledige Shuffle SOAR workflow/playbook in JSON-formaat.
   - **Functie**: Wordt getriggerd via een webhook bij detectie van verdachte SSH brute-force pogingen.
   - **Workflow Stappen**:
     1. *Parse Alert Payload*: Extraheert het bron-IP (`source_ip`), anomalie type en severity uit de JSON alert.
     2. *Validate / Whitelist Check*: Controleert of het IP niet per ongeluk een legitieme beheerder is.
     3. *Mitigation Execution*: Injecteert een actieve firewall drop-regel via iptables op het doelsysteem om de aanvaller onmiddellijk te blokkeren.
     4. *Audit & Logging*: Registreert het incident en de genomen tegenmaatregel voor compliance en analyse in de audit-logs.

2. **`docker-compose.yml`**
   - Docker Compose specificatie voor de volledige Shuffle SOAR stack op de Security EC2-node:
     - `shuffle-frontend`: Webinterface (poort `3443`).
     - `shuffle-backend`: API en webhook ingestion engine (poort `5001`).
     - `shuffle-orborus`: Worker execution engine die dynamisch micro-containers opstart voor playbook-acties.
     - `opensearch`: Database voor workflow runs, executions en logging.

3. **`deploy-soar.sh`**
   - Geautomatiseerd bash deployment script om de Shuffle stack en vereiste kernel parameters (`vm.max_map_count`) uit te rollen op de Security Stack.

4. **`rover-soar-diagram.png` & `.svg`**
   - Visuele architectuurdiagrammen van de SOAR infrastructuur en dataflow.

---

### Importeren in Shuffle SOAR UI
1. Open de Shuffle webinterface via `https://<SECURITY_STACK_IP>:3443`.
2. Ga naar **Workflows** in het linkermenu.
3. Klik op **Import Workflow** (of het upload-icoon).
4. Selecteer `shuffle-workflow-mitigation.json`.
5. De playbook nodes, acties en triggers worden direct visueel ingeladen op het canvas.
