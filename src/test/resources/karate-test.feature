@MarvelAPI @REQ_ABC2025-001
Feature: Marvel Characters API - Pruebas automatizadas

  # Información básica sobre la API
  # URL BASE: http://bp-se-test-cabcd9b246a5.herokuapp.com/{username}/api/characters
  # Todas las rutas requieren el parámetro de usuario (username) en el path

  Background:
    * url 'http://bp-se-test-cabcd9b246a5.herokuapp.com'
    * def username = 'gcardozo'
    * def basePath = '/' + username + '/api/characters'
    * configure ssl = true
    * configure logPrettyRequest = true
    * configure logPrettyResponse = true
    * configure retry = { count: 3, interval: 3000 }
    * def uuid = function() { return java.util.UUID.randomUUID() + '' }

  @GetAll
  Scenario: Obtener todos los personajes
    Given path basePath
    When method get
    Then status 200
    # La respuesta puede ser un array vacío o con elementos
    And match response == '#array'
    And print 'Respuesta: ', response

  @Get @ExistenteID
  Scenario: Obtener personaje por ID (exitoso)
    # Primero creamos un personaje para asegurarnos de que existe
    * def uniqueName = 'Spider-Man-' + uuid()

    Given path basePath
    And request
    """
    {
      "name": "#(uniqueName)",
      "alterego": "Peter Parker",
      "description": "Superhéroe arácnido",
      "powers": ["Agilidad", "Fuerza"]
    }
    """
    And header Content-Type = 'application/json'
    When method post
    Then status 201
    * def characterId = response.id

    # Ahora obtenemos el personaje creado
    Given path basePath + '/' + characterId
    When method get
    Then status 200
    And match response.name == uniqueName
    And match response.alterego == 'Peter Parker'
    And match response.description == 'Superhéroe arácnido'
    # Verificamos que cada poder está en el array de poderes
    And match response.powers contains 'Agilidad'
    And match response.powers contains 'Fuerza'

  @Get @NotFound
  Scenario: Obtener personaje por ID (no existe)
    Given path basePath + '/999999'
    When method get
    Then status 404
    And match response.error == 'Character not found'

  @Post @Valid
  Scenario: Crear un personaje (exitoso)
    # Generamos un nombre aleatorio con UUID para evitar duplicados
    * def uniqueName = 'Iron Man-' + uuid()

    Given path basePath
    And request
    """
    {
      "name": "#(uniqueName)",
      "alterego": "Tony Stark",
      "description": "Genius billionaire",
      "powers": ["Armor", "Flight"]
    }
    """
    And header Content-Type = 'application/json'
    When method post
    Then status 201
    And match response.id == '#present'
    And match response.name == uniqueName
    And match response.alterego == 'Tony Stark'
    And match response.description == 'Genius billionaire'
    # Verificamos que cada poder está en el array de poderes
    And match response.powers contains 'Armor'
    And match response.powers contains 'Flight'

  @Post @DuplicateName
  Scenario: Crear personaje con nombre duplicado (error)
    # Primero creamos un personaje con un nombre específico
    * def characterName = 'Batman-' + uuid()

    Given path basePath
    And request
    """
    {
      "name": "#(characterName)",
      "alterego": "Bruce Wayne",
      "description": "Detective de Gotham",
      "powers": ["Inteligencia", "Artes marciales"]
    }
    """
    And header Content-Type = 'application/json'
    When method post
    Then status 201

    # Intentamos crear otro personaje con el mismo nombre
    Given path basePath
    And request
    """
    {
      "name": "#(characterName)",
      "alterego": "Otro",
      "description": "Otro",
      "powers": ["Otro"]
    }
    """
    And header Content-Type = 'application/json'
    When method post
    Then status 400
    And match response.error == 'Character name already exists'

  @Post @MissingFields
  Scenario: Crear personaje con campos vacíos (error)
    Given path basePath
    And request
    """
    {
      "name": "",
      "alterego": "",
      "description": "",
      "powers": []
    }
    """
    And header Content-Type = 'application/json'
    When method post
    Then status 400
    # La API devuelve todas las validaciones de campo, verificamos que exista la validación para el nombre
    And match response.name == 'Name is required'

  @Put @Valid
  Scenario: Actualizar un personaje (exitoso)
    # Primero creamos un personaje para actualizarlo
    * def characterName = 'Hulk-' + uuid()

    Given path basePath
    And request
    """
    {
      "name": "#(characterName)",
      "alterego": "Bruce Banner",
      "description": "Científico transformado",
      "powers": ["Fuerza"]
    }
    """
    And header Content-Type = 'application/json'
    When method post
    Then status 201
    * def characterId = response.id

    # Usar la función correcta de Karate para esperar
    * karate.pause(1000)

    # Ahora actualizamos el personaje
    * def updatedDescription = 'Científico transformado en monstruo verde'

    Given path basePath + '/' + characterId
    And request
    """
    {
      "name": "#(characterName)",
      "alterego": "Bruce Banner",
      "description": "#(updatedDescription)",
      "powers": ["Fuerza sobrehumana", "Resistencia"]
    }
    """
    And header Content-Type = 'application/json'
    When method put
    Then status 200
    And match response.description == updatedDescription
    # Verificamos que cada poder está en el array de poderes actualizado
    And match response.powers contains 'Fuerza sobrehumana'
    And match response.powers contains 'Resistencia'

  @Put @NotFound
  Scenario: Actualizar personaje (no existe)
    Given path basePath + '/999999'
    And request
    """
    {
      "name": "No existe",
      "alterego": "Nadie",
      "description": "No existe",
      "powers": ["Nada"]
    }
    """
    And header Content-Type = 'application/json'
    When method put
    Then status 404
    And match response.error == 'Character not found'

  @Delete @Valid
  Scenario: Eliminar un personaje (exitoso)
    # Primero creamos un personaje para eliminarlo
    * def characterName = 'Captain America-' + uuid()

    Given path basePath
    And request
    """
    {
      "name": "#(characterName)",
      "alterego": "Steve Rogers",
      "description": "Súper soldado",
      "powers": ["Fuerza", "Agilidad"]
    }
    """
    And header Content-Type = 'application/json'
    When method post
    Then status 201
    * def characterId = response.id

    # Usar la función correcta de Karate para esperar
    * karate.pause(1000)

    # Ahora eliminamos el personaje
    Given path basePath + '/' + characterId
    When method delete
    Then status 204

    # Usar la función correcta de Karate para esperar
    * karate.pause(1000)

    # Verificamos que ya no existe
    Given path basePath + '/' + characterId
    When method get
    Then status 404
    And match response.error == 'Character not found'

  @Delete @NotFound
  Scenario: Eliminar personaje (no existe)
    Given path basePath + '/999999'
    When method delete
    Then status 404
    And match response.error == 'Character not found'
