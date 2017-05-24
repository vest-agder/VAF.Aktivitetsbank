﻿using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using VAF.Aktivitetsbank.Application;
using VAF.Aktivitetsbank.Application.Commands;
using VAF.Aktivitetsbank.Application.Handlers;
using VAF.Aktivitetsbank.Application.Handlers.Dtos;
using VAF.Aktivitetsbank.Application.Queries;

namespace VAF.Aktivitetsbank.API.Controllers
{
    [Route("aktiviteter")]
    public class AktivitetController : Controller
    {
        private readonly IQueryDispatcher _queryDispatcher;
        private readonly ICommandDispatcher _commandDispatcher;
        private readonly ILogger<UserController> _logger;
        private readonly AppOptions _options;

        public AktivitetController(IQueryDispatcher queryDispatcher, ICommandDispatcher commandDispatcher, IOptions<AppOptions> options, ILogger<UserController> logger )
        {
            _queryDispatcher = queryDispatcher;
            _commandDispatcher = commandDispatcher;
            _logger = logger;
            _options = options.Value;
        }

        [HttpGet]
        [ResponseCache(Location = ResponseCacheLocation.None, NoStore = true)]
        public IEnumerable<AktivitetDto> Get()
        {
            _logger.LogInformation("Lister ut aktiviteter");
            return _queryDispatcher.Query<AktivitetSearchQuery, IList<AktivitetDto>>(new AktivitetSearchQuery(null)).ToList();
        }

        [HttpGet("{id}")]
        [ResponseCache(Location = ResponseCacheLocation.None, NoStore = true)]
        public AktivitetDto GetAktivitet(Guid id)
        {
            _logger.LogInformation("Aktivitet detalj");
            return _queryDispatcher.Query<AktivitetQuery, AktivitetDto>(new AktivitetQuery(id));
        }

        //[AllowAnonymous]
        [Authorize(Policy = "CanChangePhoneNumbers")]
        [HttpOptions("opprettAktivitet")]
        public IActionResult GetOptions()
        {
            Response.Headers.Add("Allow", "GET, OPTIONS, POST");
            return Ok();
        }

        [Authorize(Policy = "CanChangePhoneNumbers")]
        [HttpPost("opprettAktivitet")]
        public IActionResult OpprettAktivitet([FromBody] OpprettAktivitetDto opprettAktivitetDto)
        {
            if (opprettAktivitetDto == null)
            {
                _logger.LogError("Feil data ved oppretting av aktivitet. Mangler input data.");
                return BadRequest();
            }
            opprettAktivitetDto.Id = Guid.NewGuid();
            opprettAktivitetDto.BrukerId = HttpContext.User.Identity.Name;
            if (!ModelState.IsValid)
            {
                _logger.LogError("Feil data ved oppretting av aktivitet. Feil i input data.", ModelState);
                return BadRequest(ModelState);
            }

            try
            {
                _commandDispatcher.Execute(new OpprettAktivitetCommand(opprettAktivitetDto));
                //return new NoContentResult();
                return new CreatedAtRouteResult("opprettaktivitet", new {id = opprettAktivitetDto.Id});

            }
            catch (Exception e)
            {
                Console.WriteLine(e);
                _logger.LogError("Feil i oppretting av aktivitet. Serverfeil.", e);
                return new StatusCodeResult(500);
            }
        }


        [Authorize(Policy = "CanChangePhoneNumbers")]
        [HttpPost("{aktivitetId}/kopier")]
        public IActionResult KopierAktivitet(Guid aktivitetId, [FromBody] KopierAktivitetDto kopierAktivitetDto)
        {
            if (kopierAktivitetDto == null || kopierAktivitetDto.Id != aktivitetId)
            {
                _logger.LogError("Feil data ved kopiering av aktivitet. Mangler input data.");
                return BadRequest();
            }
            if (!ModelState.IsValid)
            {
                _logger.LogError("Feil data ved kopiering av aktivitet. Feil i input data.", ModelState);
                return BadRequest(ModelState);
            }
            kopierAktivitetDto.NyAktivitetId = Guid.NewGuid();
            kopierAktivitetDto.BrukerId = HttpContext.User.Identity.Name;

            try
            {
                _commandDispatcher.Execute(new KopierAktivitetCommand(kopierAktivitetDto));
                //return new NoContentResult();
                return new CreatedAtRouteResult("kopier", new {id = kopierAktivitetDto.NyAktivitetId});

            }
            catch (Exception e)
            {
                Console.WriteLine(e);
                _logger.LogError("Feil i kopiering av aktivitet. Serverfeil.", e);
                return new StatusCodeResult(500);
            }
        }


        [Authorize(Policy = "CanChangePhoneNumbers")]
        [HttpPut("{id}")]
        public IActionResult EndreAktivitet(Guid id, [FromBody] EndreAktivitetDto endreAktivitetDto)
        {
            if (endreAktivitetDto == null || endreAktivitetDto.Id != id)
            {
                _logger.LogError("Feil data ved endring av aktivitet. Mangler input data.");
                return BadRequest();
            }
            if (!ModelState.IsValid)
            {
                _logger.LogError("Feil data ved endring av aktivitet. Feil i input data.", ModelState);
                return BadRequest(ModelState);
            }

            endreAktivitetDto.BrukerId = HttpContext.User.Identity.Name;
            try
            {
                _commandDispatcher.Execute(new EndreAktivitetCommand(endreAktivitetDto));
                return new NoContentResult();

            }
            catch (Exception e)
            {
                Console.WriteLine(e);
                _logger.LogError("Feil i endring av aktivitet. Serverfeil.", e);
                return new StatusCodeResult(500);
            }
        }
        [Authorize(Policy = "CanChangePhoneNumbers")]
        [HttpDelete("{id}")]
        public IActionResult SlettAktivitet(Guid id)
        {
            //validere guid? nullable?
            if (id == Guid.Empty)
            {
                _logger.LogError("Feil data ved sletting av aktivitet. Mangler input data.");
                return BadRequest();
            }
            var slettAktivitetDto = new SlettAktivitetDto()
            {
                Id = id,
                BrukerId = HttpContext.User.Identity.Name
            };
            try
            {
                _commandDispatcher.Execute(new SlettAktivitetCommand(slettAktivitetDto));
                return new NoContentResult();

            }
            catch (Exception e)
            {
                Console.WriteLine(e);
                _logger.LogError("Feil i sletting av aktivitet. Serverfeil.", e);
                return new StatusCodeResult(500);
            }
        }
    }
}
